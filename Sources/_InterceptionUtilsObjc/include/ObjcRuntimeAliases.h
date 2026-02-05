#import <Foundation/Foundation.h>

#if __has_include(<objc/runtime.h>) && __has_include(<objc/message.h>)
#import <objc/runtime.h>
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

extern const IMP _swiftInterceptionMsgForward;

/// A trampoline of `objc_setAssociatedObject` that is made to circumvent the
/// reference counting calls in the imported version in Swift.
void _swiftInterceptionSetAssociatedObject(
  const void* object,
  const void* key,
  id _Nullable value,
  objc_AssociationPolicy policy
);

NS_ASSUME_NONNULL_END
#endif
