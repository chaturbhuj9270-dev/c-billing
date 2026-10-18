#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <mach/mach.h>
#include <string.h>

// This Mac app is signed locally, without an Apple team. Firebase Auth is
// linked into the app itself and always asks for the data-protection keychain,
// which macOS rejects for that signature. These wrappers store the same item
// in the login keychain instead. iOS, Android, and web do not compile this.

static OSStatus (*real_add)(CFDictionaryRef, CFTypeRef *);
static OSStatus (*real_copy)(CFDictionaryRef, CFTypeRef *);
static OSStatus (*real_update)(CFDictionaryRef, CFDictionaryRef);
static OSStatus (*real_delete)(CFDictionaryRef);

static CFDictionaryRef without_data_protection(CFDictionaryRef query) {
  if (query == NULL ||
      !CFDictionaryContainsKey(query, kSecUseDataProtectionKeychain)) {
    if (query != NULL) {
      CFRetain(query);
    }
    return query;
  }

  CFMutableDictionaryRef copy =
      CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, query);
  if (copy == NULL) {
    CFRetain(query);
    return query;
  }
  CFDictionaryRemoveValue(copy, kSecUseDataProtectionKeychain);
  return copy;
}

static OSStatus cbilling_SecItemAdd(CFDictionaryRef attributes,
                                    CFTypeRef *result) {
  CFDictionaryRef cleaned = without_data_protection(attributes);
  OSStatus status = real_add(cleaned != NULL ? cleaned : attributes, result);
  if (cleaned != NULL) {
    CFRelease(cleaned);
  }
  return status;
}

static OSStatus cbilling_SecItemCopyMatching(CFDictionaryRef query,
                                             CFTypeRef *result) {
  CFDictionaryRef cleaned = without_data_protection(query);
  OSStatus status = real_copy(cleaned != NULL ? cleaned : query, result);
  if (cleaned != NULL) {
    CFRelease(cleaned);
  }
  return status;
}

static OSStatus cbilling_SecItemUpdate(CFDictionaryRef query,
                                       CFDictionaryRef attributes) {
  CFDictionaryRef cleaned_query = without_data_protection(query);
  CFDictionaryRef cleaned_attributes = without_data_protection(attributes);
  OSStatus status = real_update(
      cleaned_query != NULL ? cleaned_query : query,
      cleaned_attributes != NULL ? cleaned_attributes : attributes);
  if (cleaned_query != NULL) {
    CFRelease(cleaned_query);
  }
  if (cleaned_attributes != NULL) {
    CFRelease(cleaned_attributes);
  }
  return status;
}

static OSStatus cbilling_SecItemDelete(CFDictionaryRef query) {
  CFDictionaryRef cleaned = without_data_protection(query);
  OSStatus status = real_delete(cleaned != NULL ? cleaned : query);
  if (cleaned != NULL) {
    CFRelease(cleaned);
  }
  return status;
}

static void write_slot(void **slot, void *value) {
  vm_size_t page = vm_page_size;
  vm_address_t start = (vm_address_t)slot & ~(page - 1);
  kern_return_t result = vm_protect(
      mach_task_self(),
      start,
      page,
      FALSE,
      VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
  if (result != KERN_SUCCESS) {
    return;
  }
  *slot = value;
  vm_protect(mach_task_self(), start, page, FALSE, VM_PROT_READ);
}

static void patch_got(const struct mach_header_64 *header, void *original,
                      void *replacement) {
  if (header == NULL || original == NULL || replacement == NULL) {
    return;
  }

  const char *segments[] = {"__DATA_CONST", "__DATA", "__AUTH_CONST"};
  for (size_t segment = 0; segment < 3; segment++) {
    unsigned long size = 0;
    uint8_t *start = getsectiondata(header, segments[segment], "__got", &size);
    if (start == NULL || size < sizeof(void *)) {
      continue;
    }
    void **slots = (void **)start;
    size_t count = size / sizeof(void *);
    for (size_t index = 0; index < count; index++) {
      if (slots[index] == original) {
        write_slot(&slots[index], replacement);
      }
    }
  }
}

__attribute__((constructor)) static void cbilling_keychain_init(void) {
  real_add = dlsym(RTLD_NEXT, "SecItemAdd");
  real_copy = dlsym(RTLD_NEXT, "SecItemCopyMatching");
  real_update = dlsym(RTLD_NEXT, "SecItemUpdate");
  real_delete = dlsym(RTLD_NEXT, "SecItemDelete");

  uint32_t images = _dyld_image_count();
  for (uint32_t index = 0; index < images; index++) {
    const char *name = _dyld_get_image_name(index);
    if (name == NULL || strstr(name, "c_billing") == NULL) {
      continue;
    }
    const struct mach_header_64 *header =
        (const struct mach_header_64 *)_dyld_get_image_header(index);
    patch_got(header, (void *)real_add, (void *)cbilling_SecItemAdd);
    patch_got(header, (void *)real_copy, (void *)cbilling_SecItemCopyMatching);
    patch_got(header, (void *)real_update, (void *)cbilling_SecItemUpdate);
    patch_got(header, (void *)real_delete, (void *)cbilling_SecItemDelete);
  }
}
