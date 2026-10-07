// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class LKo extends L {
  LKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'SURVIVOR';

  @override
  String get navHome => '홈';

  @override
  String get navMap => '지도';

  @override
  String get navScan => '스캔';

  @override
  String get navSupplies => '보유품';

  @override
  String get navFirstAid => '응급처치';

  @override
  String get back => '뒤로';

  @override
  String get save => '저장';

  @override
  String get saved => '저장됨';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get add => '추가';

  @override
  String get notSure => '확실하지 않음';

  @override
  String get needsInternet => '인터넷 필요';

  @override
  String get comingSoon => '준비 중';

  @override
  String get sampleData => '샘플 데이터 — 실제 장소가 아닙니다';

  @override
  String homeStatus(String region) {
    return '오프라인 작동 · 지역팩: $region';
  }

  @override
  String get homeTitle => '지금 무엇이 필요하세요?';

  @override
  String get homeSub => '인터넷 없이 작동합니다. 위치는 이 폰 밖으로 나가지 않아요.';

  @override
  String get homeFirstAidSub => '출혈 · 화상 · 골절 · 호흡';

  @override
  String get homeNearestShelter => '가장 가까운 대피소';

  @override
  String get homeOpenMap => '지도 열기 →';

  @override
  String get homeNoShelter => '저장된 지역에 대피소가 없어요';

  @override
  String get homeAidTitle => '구호품 · 물';

  @override
  String get homeAidSub => '배급 지점 찾기';

  @override
  String get homeUxoTitle => '불발탄 주의';

  @override
  String get homeUxoSub => '만지지 말고 피하기';

  @override
  String get homeMedTitle => '병원 · 약국';

  @override
  String get homeMedSub => '마지막 확인 정보';

  @override
  String get homeFamilyTitle => '가족 집결지';

  @override
  String get homeFamilySub => '미리 정한 장소';

  @override
  String get homeWaterTitle => '마실 물 만들기';

  @override
  String get homeWaterSub => '끓이기 · 락스 · 햇빛';

  @override
  String get homeKitTitle => '비상 배낭';

  @override
  String get homeKitSub => '떠날 때 챙길 것';

  @override
  String get sosAria => '구조 신호';

  @override
  String get langAria => '언어 변경';

  @override
  String walkDistance(int minutes, String distance) {
    return '도보 $minutes분 · $distance';
  }

  @override
  String get dirN => '북쪽';

  @override
  String get dirNE => '북동쪽';

  @override
  String get dirE => '동쪽';

  @override
  String get dirSE => '남동쪽';

  @override
  String get dirS => '남쪽';

  @override
  String get dirSW => '남서쪽';

  @override
  String get dirW => '서쪽';

  @override
  String get dirNW => '북서쪽';

  @override
  String get locationFromGps => '내 GPS 위치 기준 거리';

  @override
  String get locationFallback => 'GPS 위치 없음 — 지역 중심 기준 거리';

  @override
  String get langTitle => '언어를 선택하세요';

  @override
  String get langReady => '오프라인 저장됨';

  @override
  String get langPending => '[번역 준비 중]';

  @override
  String get langRtlPreview => 'RTL 레이아웃 미리보기 (번역 안 됨)';

  @override
  String get continueLabel => '계속하기';

  @override
  String get mapTitle => '오프라인 지도';

  @override
  String mapArea(String area, String date) {
    return '저장된 지역 · $area · $date';
  }

  @override
  String get mapNoTiles => '이 지역의 지도 그림은 아직 내려받지 않았어요. 장소와 거리는 오프라인으로 작동해요.';

  @override
  String get chipShelters => '대피소';

  @override
  String get chipAid => '구호품';

  @override
  String get chipWater => '물';

  @override
  String get chipMedical => '병원·약국';

  @override
  String get dangerZone => '위험 신고 구역';

  @override
  String get source => '정보 출처';

  @override
  String verified(String date) {
    return '$date 확인';
  }

  @override
  String get compassGuide => '나침반으로 길 안내';

  @override
  String get compassTitle => '나침반 길 안내';

  @override
  String get compassHint => '폰을 평평하게 들고 화살표 방향으로 걸으세요.';

  @override
  String compassUnavailable(String direction) {
    return '이 기기에는 나침반 센서가 없어요. $direction으로 가세요.';
  }

  @override
  String get compassArrived => '30m 이내에 도착했어요';

  @override
  String get scanTitle => '카메라 스캔';

  @override
  String get scanMed => '약';

  @override
  String get scanPlant => '식물';

  @override
  String get scanWound => '상처';

  @override
  String get scanHintMed => '약병이나 포장의 글자가 잘 보이게 찍어주세요';

  @override
  String get scanHintPlant => '잎, 줄기, 꽃이 함께 보이게 찍어주세요';

  @override
  String get scanHintWound => '피가 나면 지혈이 먼저예요. 밝은 곳에서 상처 전체가 보이게 찍어주세요';

  @override
  String get scanTakePhoto => '사진 찍기';

  @override
  String get scanFromGallery => '사진에서 고르기';

  @override
  String get scanPrivacy => '사진은 이 폰 안에서만 분석되고, 어디에도 전송되지 않아요.';

  @override
  String get scanReading => '글자를 읽는 중…';

  @override
  String get medTitle => '약 정보';

  @override
  String medConfidence(String level) {
    return '인식 확신도 $level · 포장에 적힌 글자와 꼭 비교하세요';
  }

  @override
  String get confHigh => '높음';

  @override
  String get confMedium => '보통';

  @override
  String get confLow => '낮음';

  @override
  String get medWhatFor => '무엇에 쓰나요';

  @override
  String get medMustKnow => '꼭 지키세요';

  @override
  String get medExpiry => '유통기한';

  @override
  String get medExpiryNote => '기한이 지난 약은 효과가 떨어질 수 있어요. 포장에 찍힌 날짜를 확인하세요.';

  @override
  String get medSaveToBox => '내 약통에 저장';

  @override
  String get medSavedBox => '내 약통';

  @override
  String get medUnsure => '확실하지 않으면 먹지 말고 의료진에게 물어보세요.';

  @override
  String get medNotFound => '오프라인 약 목록에서 찾지 못했어요';

  @override
  String get medNotFoundHelp => '포장에 적힌 이름이나 성분을 직접 입력해 보세요.';

  @override
  String get medSearchHint => '예: 아세트아미노펜';

  @override
  String get medRecognized => '사진에서 읽은 글자';

  @override
  String get medSampleDb => '샘플 약 목록 (흔한 약 몇 가지). 전체 목록은 지역팩과 함께 내려받습니다.';

  @override
  String get plantTitle => '식물 정보';

  @override
  String get plantDontEat => '먹지 마세요';

  @override
  String get plantDontEatBody =>
      '사진만으로는 먹어도 되는지 판단할 수 없어요. 독초를 잘못 먹으면 목숨이 위험해요.';

  @override
  String get plantIdOnline =>
      '식물 식별은 인터넷이 필요하며 아직 준비 중이에요. 준비되더라도 결과는 \'무엇일 수 있다\'까지만 알려주고, 안전하다고 판정하지 않아요.';

  @override
  String get plantIfEaten => '먹었거나 만진 뒤 이상하면';

  @override
  String get plantIfEatenBody =>
      '구토, 어지러움, 숨이 차면 바로 도움을 요청하세요. 먹은 식물을 챙겨 가면 치료에 도움이 돼요.';

  @override
  String get woundTitle => '상처 확인';

  @override
  String get woundPick => '어떤 상처와 가장 비슷한가요? 앱은 진단하지 않아요. 직접 골라주세요.';

  @override
  String get woundConfirm => '맞아요';

  @override
  String get woundOther => '다른 상처예요';

  @override
  String get woundGetHelp => '이럴 땐 지금 바로 도움을 요청하세요';

  @override
  String get woundDoNow => '지금 할 일';

  @override
  String get woundOpenGuide => '단계별 안내 전체 보기';

  @override
  String get suppliesTitle => '보유품';

  @override
  String get suppliesHave => '지금 가진 것';

  @override
  String get people => '함께 있는 사람';

  @override
  String peopleCount(int count) {
    return '$count명';
  }

  @override
  String get drinkingWater => '마실 물';

  @override
  String liters(int value) {
    return '${value}L';
  }

  @override
  String get foodMeals => '식량 · 끼니 분량';

  @override
  String get addFood => '식량 추가';

  @override
  String get foodName => '식량 이름';

  @override
  String get byWater => '물 기준';

  @override
  String get byFood => '식량 기준';

  @override
  String days(String value) {
    return '$value일';
  }

  @override
  String get adviceWater =>
      '물이 먼저 떨어져요. 짠 음식과 고기·생선은 조금씩 드세요. 목이 마르면 참지 말고 마시고, 대신 땀 흘리는 활동을 줄이세요. (1인 하루 3L 기준)';

  @override
  String get adviceFood =>
      '식량이 먼저 떨어져요. 상하기 쉬운 것부터 먹고, 통조림과 건조식품은 나중을 위해 남겨두세요. (하루 3끼 기준)';

  @override
  String get makeWater => '마실 물 만들기';

  @override
  String get whatToEat => '이걸로 뭘 먹지?';

  @override
  String get waterTitle => '마실 물 만들기';

  @override
  String get waterNever => '이런 물은 어떤 방법으로도 안전하지 않아요';

  @override
  String get waterNeverBody =>
      '기름, 연료, 화학약품 냄새가 나거나 색이 이상한 물. 끓여도 독성은 사라지지 않아요.';

  @override
  String get recipesTitle => '가진 재료로 식사';

  @override
  String get filterAll => '전체';

  @override
  String get filterNoFire => '불 없이';

  @override
  String get filterNoWater => '물 없이';

  @override
  String get recipeAvailable => '지금 가능';

  @override
  String recipeMissing(String items) {
    return '$items 필요';
  }

  @override
  String servings(int count) {
    return '$count명분';
  }

  @override
  String get ingredients => '재료';

  @override
  String get howToMake => '만들기';

  @override
  String get canSafety => '통조림 안전';

  @override
  String get canSafetyBody =>
      '부풀었거나 새거나 심하게 찌그러진 캔, 열 때 거품이 나거나 냄새가 이상한 캔은 먹지 마세요. 닫힌 캔을 그대로 불에 올리면 터질 수 있어요.';

  @override
  String get faTitle => '응급처치';

  @override
  String get faSearch => '증상 검색';

  @override
  String get faCameraCheck => '카메라로 상처 확인하기';

  @override
  String get faListen => '듣기';

  @override
  String get faStop => '멈춤';

  @override
  String get faPrev => '이전';

  @override
  String get faNext => '다음 단계';

  @override
  String get faRestart => '처음으로';

  @override
  String faStepCounter(int current, int total) {
    return '$current / $total단계';
  }

  @override
  String get faReview => '의료 문구 · 출시 전 전문가 검토 대상';

  @override
  String faSources(String sources) {
    return '출처: $sources';
  }

  @override
  String get uxoTitle => '불발탄 안전';

  @override
  String get uxoWatch => '이런 물건을 조심하세요';

  @override
  String get sosTitle => '구조 신호';

  @override
  String get sosMyLocation => '내 위치 · GPS는 인터넷 없이도 작동해요';

  @override
  String get sosReadOut => '구조대와 연락되면 이 숫자를 불러주세요.';

  @override
  String get sosNoFix => 'GPS 위치 찾는 중…';

  @override
  String get sosSignals => 'SOS 신호 · 빛이나 소리로';

  @override
  String get sosTorch => '손전등 SOS';

  @override
  String get sosAlarm => '경보음';

  @override
  String get sosScreen => '화면 깜빡임';

  @override
  String get sosVibrate => '진동 신호';

  @override
  String get sosOn => '켜짐 · 눌러서 끄기';

  @override
  String get sosOff => '눌러서 켜기';

  @override
  String get sosPattern =>
      '짧게 3번 · 길게 3번 · 짧게 3번. 호루라기는 3번씩 반복하면 구조 신호로 알아들어요.';

  @override
  String get sosCheckFirst => '먼저 주변을 확인하세요';

  @override
  String get sosCheckFirstBody =>
      '교전이 있는 곳에서는 빛과 소리가 내 위치를 드러낼 수 있어요. 구조대가 가까이 있을 때 쓰세요.';

  @override
  String get emergencyNumbers => '긴급 전화';

  @override
  String get torchUnavailable => '이 기기에서는 손전등을 쓸 수 없어요';

  @override
  String get familyTitle => '가족 집결지';

  @override
  String get meet1 => '1차 집결지';

  @override
  String get meet2 => '2차 집결지 · 1차에 갈 수 없을 때';

  @override
  String get placeName => '장소 이름';

  @override
  String get placeHow => '주소 또는 찾아가는 설명';

  @override
  String get familyMembers => '가족 · 인터넷 없이도 볼 수 있어요';

  @override
  String get memberName => '이름';

  @override
  String get memberContact => '연락처';

  @override
  String get memberBlood => '혈액형';

  @override
  String get memberAllergy => '알레르기';

  @override
  String get memberMeds => '복용약';

  @override
  String get addMember => '가족 추가';

  @override
  String get familyQr => 'QR로 가족과 공유 (인터넷 불필요)';

  @override
  String get familyQrHelp => '가족이 이 코드를 사진으로 찍게 하세요. 이 화면에 입력한 내용만 들어 있어요.';

  @override
  String get prepareKit => '비상 배낭 준비하기 →';

  @override
  String get kitTitle => '비상 배낭';

  @override
  String kitProgress(int done, int total) {
    return '$done / $total 준비됨';
  }

  @override
  String fireMinutes(int minutes) {
    return '불 $minutes분';
  }

  @override
  String waterMl(int ml) {
    return '물 ${ml}ml';
  }
}
