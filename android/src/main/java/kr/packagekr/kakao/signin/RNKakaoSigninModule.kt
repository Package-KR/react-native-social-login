package kr.packagekr.kakao.signin

import android.content.pm.PackageManager
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.WritableMap
import com.facebook.react.module.annotations.ReactModule
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

import com.kakao.sdk.common.KakaoSdk
import com.kakao.sdk.user.UserApiClient
import com.kakao.sdk.auth.TokenManagerProvider

@ReactModule(name = RNKakaoSigninModule.NAME)
class RNKakaoSigninModule(
    reactContext: ReactApplicationContext
) : NativeRNKakaoSigninSpec(reactContext) {

    companion object {
        const val NAME = "RNKakaoSignin"
    }

    init {
        configureKakaoSdk()
    }

    override fun getName(): String {
        return NAME
    }

    // SDK 초기화
    private fun configureKakaoSdk() {
        if (KakaoSdk.isInitialized) {
            return
        }

        val appKey = resolveMetaData("com.kakao.sdk.AppKey")
            ?: resolveString("kakao_app_key")
            ?: return

        val customScheme = resolveString("kakao_custom_scheme")

        if (customScheme == null) {
            KakaoSdk.init(reactApplicationContext, appKey)
            return
        }

        KakaoSdk.init(reactApplicationContext, appKey, customScheme)
    }

    // 카카오톡 로그인
    @ReactMethod
    override fun login(promise: Promise) {
        val activity = reactApplicationContext.getCurrentActivity()

        if (activity == null) {
            RNKakaoError.rejectActivityDoesNotExist(promise)
            return
        }

        if (!UserApiClient.instance.isKakaoTalkLoginAvailable(activity)) {
            loginWithAccount(promise)
            return
        }

        UserApiClient.instance.loginWithKakaoTalk(activity) { token, error ->
            when {
                token != null -> promise.resolve(resolveToken(token.accessToken, token.refreshToken, token.idToken, token.scopes))
                error != null && RNKakaoError.parse(error).code == RNKakaoError.CANCELLED ->
                    RNKakaoError.reject(promise, error)
                error != null -> loginWithAccount(promise)
                else -> RNKakaoError.rejectUnknownLogin(promise)
            }
        }
    }

    // 카카오계정 로그인
    @ReactMethod
    override fun loginWithKakaoAccount(promise: Promise) {
        loginWithAccount(promise)
    }

    // 로그아웃
    @ReactMethod
    override fun logout(promise: Promise) {
        UserApiClient.instance.logout { error ->
            if (error != null) {
                RNKakaoError.reject(promise, error)
                return@logout
            }

            promise.resolve(true)
        }
    }

    // 연결 해제
    @ReactMethod
    override fun unlink(promise: Promise) {
        UserApiClient.instance.unlink { error ->
            if (error != null) {
                RNKakaoError.reject(promise, error)
                return@unlink
            }

            promise.resolve(true)
        }
    }

    // 액세스 토큰 조회
    @ReactMethod
    override fun getAccessToken(promise: Promise) {
        val token = TokenManagerProvider.instance.manager.getToken()

        if (token == null) {
            promise.resolve(null)
            return
        }

        UserApiClient.instance.accessTokenInfo { info, error ->
            if (error != null) {
                RNKakaoError.reject(promise, error)
                return@accessTokenInfo
            }

            val result = Arguments.createMap()
            result.putString("accessToken", token.accessToken)
            result.putDoubleIfPresent("expiresIn", info?.expiresIn?.toDouble())
            promise.resolve(result)
        }
    }

    // 프로필 조회
    @ReactMethod
    override fun getProfile(promise: Promise) {
        UserApiClient.instance.me { user, error ->
            if (error != null) {
                RNKakaoError.reject(promise, error)
                return@me
            }

            if (user == null) {
                RNKakaoError.rejectProfileNotFound(promise)
                return@me
            }

            val profile = Arguments.createMap()
            val account = user.kakaoAccount
            val detail = account?.profile

            profile.putStringIfPresent("id", user.id?.toString())
            profile.putStringIfPresent("name", account?.name)
            profile.putStringIfPresent("email", account?.email)
            profile.putStringIfPresent("nickname", detail?.nickname)
            profile.putStringIfPresent("profileImageUrl", detail?.profileImageUrl)
            profile.putStringIfPresent("thumbnailImageUrl", detail?.thumbnailImageUrl)
            profile.putStringIfPresent("phoneNumber", account?.phoneNumber)
            profile.putStringIfPresent("ageRange", account?.ageRange?.toString())
            profile.putStringIfPresent("birthday", account?.birthday)
            profile.putStringIfPresent("birthdayType", account?.birthdayType?.toString())
            profile.putStringIfPresent("birthyear", account?.birthyear)
            profile.putStringIfPresent("gender", account?.gender?.toString())
            profile.putBooleanIfPresent("isEmailValid", account?.isEmailValid)
            profile.putBooleanIfPresent("isEmailVerified", account?.isEmailVerified)
            profile.putBooleanIfPresent("isKorean", account?.isKorean)
            profile.putBooleanIfPresent("isDefaultImage", detail?.isDefaultImage)
            profile.putBooleanIfPresent("isLeapMonth", account?.isLeapMonth)
            profile.putStringIfPresent("connectedAt", formatDate(user.connectedAt))
            profile.putStringIfPresent("synchedAt", formatDate(user.synchedAt))
            profile.putStringIfPresent("legalName", account?.legalName)
            profile.putStringIfPresent("legalBirthDate", account?.legalBirthDate)
            profile.putStringIfPresent("legalGender", account?.legalGender?.toString())
            profile.putBooleanIfPresent("ageRangeNeedsAgreement", account?.ageRangeNeedsAgreement)
            profile.putBooleanIfPresent("birthdayNeedsAgreement", account?.birthdayNeedsAgreement)
            profile.putBooleanIfPresent("birthyearNeedsAgreement", account?.birthyearNeedsAgreement)
            profile.putBooleanIfPresent("emailNeedsAgreement", account?.emailNeedsAgreement)
            profile.putBooleanIfPresent("genderNeedsAgreement", account?.genderNeedsAgreement)
            profile.putBooleanIfPresent("isKoreanNeedsAgreement", account?.isKoreanNeedsAgreement)
            profile.putBooleanIfPresent("phoneNumberNeedsAgreement", account?.phoneNumberNeedsAgreement)
            profile.putBooleanIfPresent("profileNeedsAgreement", account?.profileNeedsAgreement)
            profile.putBooleanIfPresent("profileNicknameNeedsAgreement", account?.profileNicknameNeedsAgreement)
            profile.putBooleanIfPresent("profileImageNeedsAgreement", account?.profileImageNeedsAgreement)
            profile.putBooleanIfPresent("nameNeedsAgreement", account?.nameNeedsAgreement)
            profile.putBooleanIfPresent("legalNameNeedsAgreement", account?.legalNameNeedsAgreement)
            profile.putBooleanIfPresent("legalBirthDateNeedsAgreement", account?.legalBirthDateNeedsAgreement)
            profile.putBooleanIfPresent("legalGenderNeedsAgreement", account?.legalGenderNeedsAgreement)
            promise.resolve(profile)
        }
    }

    // 배송지 조회
    @ReactMethod
    override fun shippingAddresses(promise: Promise) {
        UserApiClient.instance.shippingAddresses { addresses, error ->
            if (error != null) {
                RNKakaoError.reject(promise, error)
                return@shippingAddresses
            }

            if (addresses == null) {
                RNKakaoError.rejectShippingAddressesNotFound(promise)
                return@shippingAddresses
            }

            val result = Arguments.createMap()
            result.putStringIfPresent("userId", addresses.userId?.toString())
            result.putBooleanIfPresent("needsAgreement", addresses.needsAgreement)

            val array = Arguments.createArray()
            addresses.shippingAddresses?.map { addr ->
                Arguments.createMap().apply {
                    putStringIfPresent("id", addr.id?.toString())
                    putStringIfPresent("name", addr.name)
                    putBooleanIfPresent("isDefault", addr.isDefault)
                    putStringIfPresent("updatedAt", formatDate(addr.updatedAt))
                    putStringIfPresent("type", addr.type?.toString())
                    putStringIfPresent("baseAddress", addr.baseAddress)
                    putStringIfPresent("detailAddress", addr.detailAddress)
                    putStringIfPresent("receiverName", addr.receiverName)
                    putStringIfPresent("receiverPhoneNumber1", addr.receiverPhoneNumber1)
                    putStringIfPresent("receiverPhoneNumber2", addr.receiverPhoneNumber2)
                    putStringIfPresent("zoneNumber", addr.zoneNumber)
                    putStringIfPresent("zipCode", addr.zipCode)
                }
            }?.forEach(array::pushMap)
            result.putArray("shippingAddresses", array)

            promise.resolve(result)
        }
    }

    // 서비스 약관 조회
    @ReactMethod
    override fun serviceTerms(promise: Promise) {
        UserApiClient.instance.serviceTerms { terms, error ->
            if (error != null) {
                RNKakaoError.reject(promise, error)
                return@serviceTerms
            }

            val result = Arguments.createMap()
            terms?.id?.let { result.putString("userId", it.toString()) }

            val array = Arguments.createArray()
            terms?.serviceTerms?.map { term ->
                Arguments.createMap().apply {
                    putStringIfPresent("tag", term.tag)
                    putBoolean("agreed", term.agreed)
                    putBoolean("required", term.required)
                    putBoolean("revocable", term.revocable)
                    putStringIfPresent("agreedAt", formatDate(term.agreedAt))
                }
            }?.forEach(array::pushMap)
            result.putArray("serviceTerms", array)

            promise.resolve(result)
        }
    }

    // 카카오계정 웹 로그인
    private fun loginWithAccount(promise: Promise) {
        val activity = reactApplicationContext.getCurrentActivity()

        if (activity == null) {
            RNKakaoError.rejectActivityDoesNotExist(promise)
            return
        }

        UserApiClient.instance.loginWithKakaoAccount(activity) { token, error ->
            when {
                token != null -> promise.resolve(resolveToken(token.accessToken, token.refreshToken, token.idToken, token.scopes))
                error != null -> RNKakaoError.reject(promise, error)
                else -> RNKakaoError.rejectUnknownLogin(promise)
            }
        }
    }

    // 앱 메타데이터 조회
    private fun resolveMetaData(key: String): String? {
        return try {
            val packageInfo = reactApplicationContext.packageManager.getApplicationInfo(
                reactApplicationContext.packageName,
                PackageManager.GET_META_DATA
            )

            packageInfo.metaData?.getString(key)?.trim()?.takeIf { it.isNotEmpty() }
        } catch (_: Exception) {
            null
        }
    }

    // 문자열 리소스 조회
    private fun resolveString(name: String): String? {
        val resourceId = reactApplicationContext.resources.getIdentifier(
            name,
            "string",
            reactApplicationContext.packageName
        )

        if (resourceId == 0) {
            return null
        }

        return reactApplicationContext.getString(resourceId).trim().takeIf { it.isNotEmpty() }
    }

    // 토큰 응답 생성
    private fun resolveToken(accessToken: String?, refreshToken: String?, idToken: String? = null, scopes: List<String>? = null): WritableMap {
        val token = Arguments.createMap()
        val current = TokenManagerProvider.instance.manager.getToken()

        token.putString("accessToken", accessToken)
        token.putString("refreshToken", refreshToken)
        token.putStringIfPresent("idToken", idToken)
        token.putStringIfPresent("accessTokenExpiresAt", formatDate(current?.accessTokenExpiresAt))
        token.putStringIfPresent("refreshTokenExpiresAt", formatDate(current?.refreshTokenExpiresAt))

        if (scopes != null) {
            val scopeArray = Arguments.createArray()
            scopes.forEach { scopeArray.pushString(it) }
            token.putArray("scopes", scopeArray)
        }

        return token
    }

    // 선택값 입력
    private fun WritableMap.putStringIfPresent(key: String, value: String?) {
        val normalized = value?.trim()?.takeIf { it.isNotEmpty() }

        if (normalized != null) {
            putString(key, normalized)
        }
    }

    private fun WritableMap.putBooleanIfPresent(key: String, value: Boolean?) {
        if (value != null) {
            putBoolean(key, value)
        }
    }

    private fun WritableMap.putDoubleIfPresent(key: String, value: Double?) {
        if (value != null) {
            putDouble(key, value)
        }
    }

    // 날짜 포맷 변환
    private fun formatDate(date: Date?): String? {
        if (date == null) {
            return null
        }

        val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        formatter.timeZone = TimeZone.getTimeZone("UTC")
        return formatter.format(date)
    }
}
