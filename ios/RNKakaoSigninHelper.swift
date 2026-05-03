import Foundation
import KakaoSDKAuth

// 공통 헬퍼
enum RNKakaoSigninHelper {

  // 날짜 포맷터
  static let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(secondsFromGMT: 0)
    return f
  }()

  // 토큰 변환
  static func tokenToDict(_ token: OAuthToken?) -> [String: Any] {
    guard let token = token else { return [:] }
    return compact([
      "accessToken": token.accessToken,
      "refreshToken": token.refreshToken,
      "idToken": token.idToken as Any,
      "accessTokenExpiresAt": dateFormatter.string(from: token.expiredAt),
      "refreshTokenExpiresAt": dateFormatter.string(from: token.refreshTokenExpiredAt),
      "scopes": token.scopes as Any,
    ])
  }

  // 선택값 제거
  static func compact(_ dict: [String: Any?]) -> [String: Any] {
    return dict.reduce(into: [String: Any]()) { result, item in
      guard let rawValue = item.value,
            let value = unwrap(rawValue) else {
        return
      }

      if value is NSNull {
        return
      }

      if let string = value as? String {
        let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.isEmpty {
          result[item.key] = normalized
        }
        return
      }

      result[item.key] = value
    }
  }

  // Optional 해제
  private static func unwrap(_ value: Any) -> Any? {
    let mirror = Mirror(reflecting: value)

    guard mirror.displayStyle == .optional else {
      return value
    }

    return mirror.children.first?.value
  }

  // 앱 키 해석
  static func resolveAppKey() -> String? {
    guard let value = Bundle.main.object(forInfoDictionaryKey: "KAKAO_APP_KEY") as? String else {
      return nil
    }

    let appKey = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return appKey.isEmpty ? nil : appKey
  }

  // 커스텀 URL scheme 해석
  static func resolveCustomScheme(appKey: String?) -> String? {
    if let configured = Bundle.main.object(forInfoDictionaryKey: "KAKAO_APP_SCHEME") as? String {
      let scheme = configured.trimmingCharacters(in: .whitespacesAndNewlines)
      if !scheme.isEmpty {
        return scheme
      }
    }

    guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
      return nil
    }

    let expectedScheme = appKey.map { "kakao\($0)" }

    for urlType in urlTypes {
      guard let schemes = urlType["CFBundleURLSchemes"] as? [String] else {
        continue
      }

      if let urlName = urlType["CFBundleURLName"] as? String,
         urlName.caseInsensitiveCompare("KAKAO") == .orderedSame,
         let namedScheme = normalizedScheme(from: schemes.first) {
        return namedScheme
      }

      if let expectedScheme,
         let matchingScheme = schemes.compactMap({ normalizedScheme(from: $0) }).first(where: { $0 == expectedScheme }) {
        return matchingScheme
      }

      if let fallbackScheme = schemes.compactMap({ normalizedScheme(from: $0) }).first(where: { $0.hasPrefix("kakao") }) {
        return fallbackScheme
      }
    }

    return nil
  }

  // URL scheme 정규화
  private static func normalizedScheme(from value: String?) -> String? {
    guard let value = value else {
      return nil
    }

    let scheme = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return scheme.isEmpty ? nil : scheme
  }
}
