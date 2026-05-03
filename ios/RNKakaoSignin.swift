import Foundation

import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

@objc(RNKakaoSignin)
class RNKakaoSignin: NSObject {

  // SDK 초기화
  public override init() {
    super.init()
    configureKakaoSdk()
  }

  private func configureKakaoSdk() {
    if let appKey = RNKakaoSigninHelper.resolveAppKey() {
      if let customScheme = RNKakaoSigninHelper.resolveCustomScheme(appKey: appKey) {
        KakaoSDK.initSDK(appKey: appKey, customScheme: customScheme)
      } else {
        KakaoSDK.initSDK(appKey: appKey)
      }
    }
  }

  // 메인 큐 초기화
  @objc static func requiresMainQueueSetup() -> Bool { true }

  // 카카오톡 로그인 URL 확인
  @objc(isKakaoTalkLoginUrl:)
  static func isKakaoTalkLoginUrl(_ url: URL) -> Bool {
    return AuthApi.isKakaoTalkLoginUrl(url)
  }

  // 카카오톡 로그인 URL 처리
  @objc(handleOpenUrl:)
  static func handleOpenUrl(_ url: URL) -> Bool {
    return AuthController.handleOpenUrl(url: url)
  }

  // 카카오 로그인
  @objc(login:rejecter:)
  func login(_ resolve: @escaping RCTPromiseResolveBlock,
             rejecter reject: @escaping RCTPromiseRejectBlock) {
    runOnMain {
      let completion = self.tokenHandler(resolve, reject)

      if UserApi.isKakaoTalkLoginAvailable() {
        UserApi.shared.loginWithKakaoTalk(completion: completion)
        return
      }

      UserApi.shared.loginWithKakaoAccount(completion: completion)
    }
  }

  // 카카오계정 로그인
  @objc(loginWithKakaoAccount:rejecter:)
  func loginWithKakaoAccount(_ resolve: @escaping RCTPromiseResolveBlock,
                             rejecter reject: @escaping RCTPromiseRejectBlock) {
    runOnMain { UserApi.shared.loginWithKakaoAccount(completion: self.tokenHandler(resolve, reject)) }
  }

  // 로그아웃
  @objc(logout:rejecter:)
  func logout(_ resolve: @escaping RCTPromiseResolveBlock,
              rejecter reject: @escaping RCTPromiseRejectBlock) {
    runOnMain { UserApi.shared.logout(completion: self.unitHandler(resolve, reject)) }
  }

  // 연결 끊기
  @objc(unlink:rejecter:)
  func unlink(_ resolve: @escaping RCTPromiseResolveBlock,
              rejecter reject: @escaping RCTPromiseRejectBlock) {
    runOnMain { UserApi.shared.unlink(completion: self.unitHandler(resolve, reject)) }
  }

  // 토큰 정보 조회
  @objc(getAccessToken:rejecter:)
  func getAccessToken(_ resolve: @escaping RCTPromiseResolveBlock,
                      rejecter reject: @escaping RCTPromiseRejectBlock) {
    runOnMain {
      guard let token = TokenManager.manager.getToken() else {
        resolve(nil)
        return
      }

      UserApi.shared.accessTokenInfo { info, error in
        if let error = error { self.reject(reject, error) }
        else {
          resolve(RNKakaoSigninHelper.compact([
            "accessToken": token.accessToken,
            "expiresIn": info?.expiresIn as Any,
          ]))
        }
      }
    }
  }

  // 프로필 조회
  @objc(getProfile:rejecter:)
  func getProfile(_ resolve: @escaping RCTPromiseResolveBlock,
                  rejecter reject: @escaping RCTPromiseRejectBlock) {
    runOnMain {
      UserApi.shared.me { user, error in
        if let error = error { self.reject(reject, error) }
        else if user == nil {
          self.rejectParsed(reject, RNKakaoError.profileNotFound())
        }
        else {
          let account = user?.kakaoAccount
          let profile = account?.profile
          let fmt = RNKakaoSigninHelper.dateFormatter
          let result = RNKakaoSigninHelper.compact([
            "id": user?.id.map { String($0) } as Any,
            "name": account?.name as Any,
            "email": account?.email as Any,
            "nickname": profile?.nickname as Any,
            "profileImageUrl": profile?.profileImageUrl?.absoluteString as Any,
            "thumbnailImageUrl": profile?.thumbnailImageUrl?.absoluteString as Any,
            "phoneNumber": account?.phoneNumber as Any,
            "ageRange": account?.ageRange?.rawValue as Any,
            "birthday": account?.birthday as Any,
            "birthdayType": account?.birthdayType as Any,
            "birthyear": account?.birthyear as Any,
            "gender": account?.gender?.rawValue as Any,
            "isEmailValid": account?.isEmailValid as Any,
            "isEmailVerified": account?.isEmailVerified as Any,
            "isKorean": account?.isKorean as Any,
            "isDefaultImage": profile?.isDefaultImage as Any,
            "connectedAt": user?.connectedAt.map { fmt.string(from: $0) } as Any,
            "synchedAt": user?.synchedAt.map { fmt.string(from: $0) } as Any,
            "ci": account?.ci as Any,
            "ciAuthenticatedAt": account?.ciAuthenticatedAt.map { fmt.string(from: $0) } as Any,
            "legalName": account?.legalName as Any,
            "legalBirthDate": account?.legalBirthDate as Any,
            "legalGender": account?.legalGender?.rawValue as Any,
            "ageRangeNeedsAgreement": account?.ageRangeNeedsAgreement as Any,
            "birthdayNeedsAgreement": account?.birthdayNeedsAgreement as Any,
            "birthyearNeedsAgreement": account?.birthyearNeedsAgreement as Any,
            "emailNeedsAgreement": account?.emailNeedsAgreement as Any,
            "genderNeedsAgreement": account?.genderNeedsAgreement as Any,
            "isKoreanNeedsAgreement": account?.isKoreanNeedsAgreement as Any,
            "phoneNumberNeedsAgreement": account?.phoneNumberNeedsAgreement as Any,
            "profileNeedsAgreement": account?.profileNeedsAgreement as Any,
            "profileNicknameNeedsAgreement": account?.profileNicknameNeedsAgreement as Any,
            "profileImageNeedsAgreement": account?.profileImageNeedsAgreement as Any,
            "nameNeedsAgreement": account?.nameNeedsAgreement as Any,
            "ciNeedsAgreement": account?.ciNeedsAgreement as Any,
            "legalNameNeedsAgreement": account?.legalNameNeedsAgreement as Any,
            "legalBirthDateNeedsAgreement": account?.legalBirthDateNeedsAgreement as Any,
            "legalGenderNeedsAgreement": account?.legalGenderNeedsAgreement as Any,
          ])
          resolve(result)
        }
      }
    }
  }

  // 배송지 조회
  @objc(shippingAddresses:rejecter:)
  func shippingAddresses(_ resolve: @escaping RCTPromiseResolveBlock,
                         rejecter reject: @escaping RCTPromiseRejectBlock) {
    runOnMain {
      let fmt = RNKakaoSigninHelper.dateFormatter
      UserApi.shared.shippingAddresses { addresses, error in
        if let error = error { self.reject(reject, error) }
        else if addresses == nil {
          self.rejectParsed(reject, RNKakaoError.shippingAddressesNotFound())
        }
        else {
          resolve(RNKakaoSigninHelper.compact([
            "userId": addresses?.userId.map { String($0) } as Any,
            "needsAgreement": addresses?.needsAgreement as Any,
            "shippingAddresses": addresses?.shippingAddresses?.map { addr in RNKakaoSigninHelper.compact([
              "id": String(addr.id),
              "name": addr.name as Any,
              "isDefault": addr.isDefault as Any,
              "updatedAt": addr.updatedAt.map { fmt.string(from: $0) } as Any,
              "type": addr.type?.rawValue as Any,
              "baseAddress": addr.baseAddress as Any,
              "detailAddress": addr.detailAddress as Any,
              "receiverName": addr.receiverName as Any,
              "receiverPhoneNumber1": addr.receiverPhoneNumber1 as Any,
              "receiverPhoneNumber2": addr.receiverPhoneNumber2 as Any,
              "zoneNumber": addr.zoneNumber as Any,
              "zipCode": addr.zipCode as Any,
            ])} as Any,
          ]))
        }
      }
    }
  }

  // 서비스 약관 조회
  @objc(serviceTerms:rejecter:)
  func serviceTerms(_ resolve: @escaping RCTPromiseResolveBlock,
                    rejecter reject: @escaping RCTPromiseRejectBlock) {
    runOnMain {
      let fmt = RNKakaoSigninHelper.dateFormatter
      UserApi.shared.serviceTerms { terms, error in
        if let error = error { self.reject(reject, error) }
        else {
          let serviceTerms = terms?.serviceTerms ?? []
          let result = RNKakaoSigninHelper.compact([
            "userId": terms.map { String($0.id) } as Any,
            "serviceTerms": serviceTerms.map { term -> [String: Any] in
              var dict: [String: Any] = [
                "tag": term.tag,
                "agreed": term.agreed,
                "required": term.required,
                "revocable": term.revocable,
              ]
              if let agreedAt = term.agreedAt {
                dict["agreedAt"] = fmt.string(from: agreedAt)
              }
              return dict
            },
          ])
          resolve(result)
        }
      }
    }
  }

  // 메인 스레드 실행
  private func runOnMain(_ action: @escaping () -> Void) {
    DispatchQueue.main.async(execute: action)
  }

  // 토큰 응답 콜백
  private func tokenHandler(
    _ resolve: @escaping RCTPromiseResolveBlock,
    _ reject: @escaping RCTPromiseRejectBlock
  ) -> (OAuthToken?, Error?) -> Void {
    return { token, error in
      if let error = error { self.reject(reject, error) }
      else if token == nil {
        self.rejectParsed(reject, RNKakaoError.unknownLogin())
      }
      else { resolve(RNKakaoSigninHelper.tokenToDict(token)) }
    }
  }

  // 성공 응답 콜백
  private func unitHandler(
    _ resolve: @escaping RCTPromiseResolveBlock,
    _ reject: @escaping RCTPromiseRejectBlock
  ) -> (Error?) -> Void {
    return { error in
      if let error = error { self.reject(reject, error) }
      else { resolve(true) }
    }
  }

  // 에러 변환
  private func reject(_ reject: RCTPromiseRejectBlock, _ error: Error) {
    rejectParsed(reject, RNKakaoError.parse(error))
  }

  private func rejectParsed(_ reject: RCTPromiseRejectBlock, _ error: RNKakaoError.ParsedError) {
    var userInfo: [String: Any] = [NSLocalizedDescriptionKey: error.message]

    if let sdkMessage = error.sdkMessage {
      userInfo["sdkMessage"] = sdkMessage
    }

    let nativeError = NSError(domain: "RNKakaoSignin", code: 0, userInfo: userInfo)
    reject(error.code, error.message, nativeError)
  }
}
