export type KakaoOAuthToken = {
  accessToken: string;
  refreshToken: string;
  idToken: string;
  accessTokenExpiresAt: Date;
  refreshTokenExpiresAt: Date;
  scopes: string[];
};

export type KakaoAccessTokenInfo = {
  accessToken: string;
  expiresIn: string;
};

export type KakaoShippingAddress = {
  id: string;
  name: string;
  isDefault: boolean;
  updatedAt: string;
  type: string;
  baseAddress: string;
  detailAddress: string;
  receiverName: string;
  receiverPhoneNumber1: string;
  receiverPhoneNumber2: string;
  zoneNumber: string;
  zipCode: string;
};

export type KakaoShippingAddresses = {
  userId: string;
  needsAgreement: boolean;
  shippingAddresses: KakaoShippingAddress[];
};

export type KakaoServiceTerm = {
  tag: string;
  agreed: boolean;
  required: boolean;
  revocable: boolean;
  agreedAt?: string;
};

export type KakaoServiceTerms = {
  userId: string;
  serviceTerms: KakaoServiceTerm[];
};

export type KakaoProfile = {
  id: number;
  email: string;
  name: string;
  nickname: string;
  profileImageUrl: string;
  thumbnailImageUrl: string;
  phoneNumber: string;
  ageRange: string;
  birthday: string;
  birthdayType: string;
  birthyear: string;
  gender: string;
  isEmailValid: boolean;
  isEmailVerified: boolean;
  isKorean: boolean;
  ageRangeNeedsAgreement?: boolean;
  birthdayNeedsAgreement?: boolean;
  birthyearNeedsAgreement?: boolean;
  emailNeedsAgreement?: boolean;
  genderNeedsAgreement?: boolean;
  isKoreanNeedsAgreement?: boolean;
  phoneNumberNeedsAgreement?: boolean;
  profileNeedsAgreement?: boolean;
};
