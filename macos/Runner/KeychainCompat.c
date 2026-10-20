#include <CoreFoundation/CoreFoundation.h>
#include <Security/SecAccess.h>
#include <Security/SecACL.h>
#include <Security/Security.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <mach/mach.h>
#include <stdbool.h>
#include <string.h>

// errSecInteractionNotAllowed: a prompt would have been shown.
// errSecAuthFailed / errSecUserCanceled: the login-keychain dialog was denied.
enum {
  cbilling_err_interaction = -25308,
  cbilling_err_auth_failed = -25293,
  cbilling_err_user_canceled = -128
};

// This Mac app is signed locally, without an Apple team. Firebase Auth is
// linked into the app itself and always asks for the data-protection keychain,
// which macOS rejects for that signature. These wrappers store the same item
// in the login keychain instead. iOS, Android, and web do not compile this.

static OSStatus (*real_add)(CFDictionaryRef, CFTypeRef *);
static OSStatus (*real_copy)(CFDictionaryRef, CFTypeRef *);
static OSStatus (*real_update)(CFDictionaryRef, CFDictionaryRef);
static OSStatus (*real_delete)(CFDictionaryRef);

static bool is_secure_storage(CFDictionaryRef query) {
  if (query == NULL) {
    return false;
  }
  CFTypeRef service = CFDictionaryGetValue(query, kSecAttrService);
  if (service == NULL || CFGetTypeID(service) != CFStringGetTypeID()) {
    return false;
  }
  return CFStringCompare((CFStringRef)service,
                         CFSTR("flutter_secure_storage_service"),
                         0) == kCFCompareEqualTo;
}

static bool prompt_was_blocked(OSStatus status) {
  return status == cbilling_err_interaction ||
         status == cbilling_err_auth_failed ||
         status == cbilling_err_user_canceled;
}

// An access list with no trusted-app restriction and no password prompt.
// A locally signed debug build changes identity on every launch, so an
// item locked to one binary asks for the login password every time.
static SecAccessRef open_access(void) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  SecAccessRef access = NULL;
  if (SecAccessCreate(CFSTR("c_billing"), NULL, &access) != errSecSuccess ||
      access == NULL) {
    return NULL;
  }

  CFArrayRef acls = NULL;
  if (SecAccessCopyACLList(access, &acls) != errSecSuccess || acls == NULL) {
    CFRelease(access);
    return NULL;
  }
  CFIndex count = CFArrayGetCount(acls);
  for (CFIndex index = 0; index < count; index++) {
    SecACLRef acl = (SecACLRef)CFArrayGetValueAtIndex(acls, index);
    SecACLSetContents(acl, NULL, CFSTR("c_billing"), 0);
  }
  CFRelease(acls);
#pragma clang diagnostic pop
  return access;
}

static CFMutableDictionaryRef prepare(CFDictionaryRef query, bool for_add) {
  if (query == NULL) {
    return NULL;
  }
  CFMutableDictionaryRef copy =
      CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, query);
  if (copy == NULL) {
    return NULL;
  }
  CFDictionaryRemoveValue(copy, kSecUseDataProtectionKeychain);
  if (!is_secure_storage(query)) {
    return copy;
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  CFDictionarySetValue(copy, kSecUseAuthenticationUI, kSecUseAuthenticationUIFail);
#pragma clang diagnostic pop
  if (for_add) {
    SecAccessRef access = open_access();
    if (access != NULL) {
      CFDictionarySetValue(copy, kSecAttrAccess, access);
      CFRelease(access);
    }
  }
  return copy;
}

static void drop_locked_item(CFDictionaryRef query) {
  CFMutableDictionaryRef copy = prepare(query, false);
  if (copy == NULL) {
    return;
  }
  CFDictionaryRemoveValue(copy, kSecReturnData);
  CFDictionaryRemoveValue(copy, kSecReturnAttributes);
  CFDictionaryRemoveValue(copy, kSecReturnRef);
  CFDictionaryRemoveValue(copy, kSecMatchLimit);
  real_delete(copy);
  CFRelease(copy);
}

static OSStatus cbilling_SecItemAdd(CFDictionaryRef attributes,
                                    CFTypeRef *result) {
  CFMutableDictionaryRef cleaned = prepare(attributes, true);
  OSStatus status = real_add(cleaned != NULL ? cleaned : attributes, result);
  if (cleaned != NULL) {
    CFRelease(cleaned);
  }
  if (is_secure_storage(attributes) && prompt_was_blocked(status)) {
    drop_locked_item(attributes);
    cleaned = prepare(attributes, true);
    status = real_add(cleaned != NULL ? cleaned : attributes, result);
    if (cleaned != NULL) {
      CFRelease(cleaned);
    }
  }
  return status;
}

static OSStatus cbilling_SecItemCopyMatching(CFDictionaryRef query,
                                             CFTypeRef *result) {
  CFMutableDictionaryRef cleaned = prepare(query, false);
  OSStatus status = real_copy(cleaned != NULL ? cleaned : query, result);
  if (cleaned != NULL) {
    CFRelease(cleaned);
  }
  if (is_secure_storage(query) && prompt_was_blocked(status)) {
    drop_locked_item(query);
    if (result != NULL) {
      *result = NULL;
    }
    return errSecItemNotFound;
  }
  return status;
}

static OSStatus cbilling_SecItemUpdate(CFDictionaryRef query,
                                       CFDictionaryRef attributes) {
  CFMutableDictionaryRef cleaned_query = prepare(query, false);
  CFMutableDictionaryRef cleaned_attributes = prepare(attributes, false);
  OSStatus status = real_update(
      cleaned_query != NULL ? cleaned_query : query,
      cleaned_attributes != NULL ? cleaned_attributes : attributes);
  if (cleaned_query != NULL) {
    CFRelease(cleaned_query);
  }
  if (cleaned_attributes != NULL) {
    CFRelease(cleaned_attributes);
  }
  if (is_secure_storage(query) && prompt_was_blocked(status)) {
    drop_locked_item(query);
    return errSecItemNotFound;
  }
  return status;
}

static OSStatus cbilling_SecItemDelete(CFDictionaryRef query) {
  CFMutableDictionaryRef cleaned = prepare(query, false);
  OSStatus status = real_delete(cleaned != NULL ? cleaned : query);
  if (cleaned != NULL) {
    CFRelease(cleaned);
  }
  if (is_secure_storage(query) &&
      (status == errSecItemNotFound || prompt_was_blocked(status))) {
    return errSecSuccess;
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
