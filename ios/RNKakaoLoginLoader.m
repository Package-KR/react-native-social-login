#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 카카오 로그인 URL을 체크하는 Swift 클래스 forward declaration
@interface RNKakaoLogin : NSObject
+ (BOOL)isKakaoTalkLoginUrl:(NSURL *)url;
+ (BOOL)handleOpenUrl:(NSURL *)url;
@end

typedef BOOL (*RNKakaoOpenURLIMP)(id, SEL, UIApplication *, NSURL *, NSDictionary *);
typedef BOOL (*RNKakaoContinueUserActivityIMP)(id, SEL, UIApplication *, NSUserActivity *, void (^)(NSArray<id<UIUserActivityRestoring>> *));

static RNKakaoOpenURLIMP rnKakaoOriginalOpenURLIMP = NULL;
static RNKakaoContinueUserActivityIMP rnKakaoOriginalContinueUserActivityIMP = NULL;

static BOOL RNKakaoLogin_openURL(id self, SEL _cmd, UIApplication *app, NSURL *url, NSDictionary *options) {
  NSLog(@"[RNKakaoLogin] openURL received: %@", url.absoluteString);

  if ([RNKakaoLogin isKakaoTalkLoginUrl:url]) {
    return [RNKakaoLogin handleOpenUrl:url];
  }

  if (rnKakaoOriginalOpenURLIMP != NULL) {
    return rnKakaoOriginalOpenURLIMP(self, _cmd, app, url, options);
  }

  return NO;
}

static BOOL RNKakaoLogin_continueUserActivity(
  id self,
  SEL _cmd,
  UIApplication *app,
  NSUserActivity *userActivity,
  void (^restorationHandler)(NSArray<id<UIUserActivityRestoring>> *)
) {
  NSURL *url = userActivity.webpageURL;
  NSLog(@"[RNKakaoLogin] continueUserActivity received: %@", url.absoluteString);

  if (url != nil && [RNKakaoLogin isKakaoTalkLoginUrl:url]) {
    return [RNKakaoLogin handleOpenUrl:url];
  }

  if (rnKakaoOriginalContinueUserActivityIMP != NULL) {
    return rnKakaoOriginalContinueUserActivityIMP(self, _cmd, app, userActivity, restorationHandler);
  }

  return NO;
}

// +load는 iOS가 delegate 메서드를 캐싱하기 전에 호출됨
@interface RNKakaoLoginLoader : NSObject
@end

@implementation RNKakaoLoginLoader

+ (void)load {
  int classCount = objc_getClassList(NULL, 0);
  if (classCount <= 0) return;

  Class *classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * (NSUInteger)classCount);
  classCount = objc_getClassList(classes, classCount);

  for (int i = 0; i < classCount; i += 1) {
    Class cls = classes[i];
    if (!class_conformsToProtocol(cls, @protocol(UIApplicationDelegate))) continue;

    SEL openURLSelector = @selector(application:openURL:options:);
    Method openURLMethod = class_getInstanceMethod(cls, openURLSelector);

    if (openURLMethod == NULL) {
      class_addMethod(cls, openURLSelector, (IMP)RNKakaoLogin_openURL, "B@:@@@");
      NSLog(@"[RNKakaoLogin] openURL added to %@", NSStringFromClass(cls));
    } else {
      rnKakaoOriginalOpenURLIMP = (RNKakaoOpenURLIMP)method_getImplementation(openURLMethod);
      method_setImplementation(openURLMethod, (IMP)RNKakaoLogin_openURL);
      NSLog(@"[RNKakaoLogin] openURL swizzled on %@", NSStringFromClass(cls));
    }

    SEL continueSelector = @selector(application:continueUserActivity:restorationHandler:);
    Method continueMethod = class_getInstanceMethod(cls, continueSelector);

    if (continueMethod == NULL) {
      class_addMethod(cls, continueSelector, (IMP)RNKakaoLogin_continueUserActivity, "B@:@@@@");
      NSLog(@"[RNKakaoLogin] continueUserActivity added to %@", NSStringFromClass(cls));
    } else {
      rnKakaoOriginalContinueUserActivityIMP = (RNKakaoContinueUserActivityIMP)method_getImplementation(continueMethod);
      method_setImplementation(continueMethod, (IMP)RNKakaoLogin_continueUserActivity);
      NSLog(@"[RNKakaoLogin] continueUserActivity swizzled on %@", NSStringFromClass(cls));
    }
  }

  free(classes);
}

@end
