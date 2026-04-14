import { type ConfigPlugin, withInfoPlist } from "@expo/config-plugins";
import type { KakaoSigninPluginProps } from "..";

const KAKAO_SCHEMES = ["kakaokompassauth", "kakaotalk"];

/**
 * Info.plist에 카카오 URL Scheme, KAKAO_APP_KEY, LSApplicationQueriesSchemes 추가
 * AppDelegate 수정은 불필요 (RNKakaoLoginLoader.m에서 swizzling으로 자동 처리)
 */
const modifyInfoPlist: ConfigPlugin<KakaoSigninPluginProps> = (
  config,
  props
) => {
  return withInfoPlist(config, (config) => {
    const kakaoScheme = `kakao${props.kakaoAppKey}`;

    // KAKAO_APP_KEY
    config.modResults.KAKAO_APP_KEY = props.kakaoAppKey;

    // CFBundleURLTypes - kakao{앱키} scheme 등록
    if (!Array.isArray(config.modResults.CFBundleURLTypes)) {
      config.modResults.CFBundleURLTypes = [];
    }

    const hasKakaoScheme = config.modResults.CFBundleURLTypes.some((item) =>
      item.CFBundleURLSchemes?.includes(kakaoScheme)
    );

    if (!hasKakaoScheme) {
      config.modResults.CFBundleURLTypes.push({
        CFBundleURLSchemes: [kakaoScheme],
      });
    }

    // LSApplicationQueriesSchemes - 카카오톡 앱 탐지용
    if (!Array.isArray(config.modResults.LSApplicationQueriesSchemes)) {
      config.modResults.LSApplicationQueriesSchemes = [];
    }

    const allSchemes = [kakaoScheme, ...KAKAO_SCHEMES];
    allSchemes.forEach((scheme) => {
      if (!config.modResults.LSApplicationQueriesSchemes?.includes(scheme)) {
        config.modResults.LSApplicationQueriesSchemes?.push(scheme);
      }
    });

    return config;
  });
};

export const withIosKakaoSignin: ConfigPlugin<KakaoSigninPluginProps> = (
  config,
  props
) => {
  config = modifyInfoPlist(config, props);

  return config;
};
