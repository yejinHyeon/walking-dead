// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SURVIVOR';

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Map';

  @override
  String get navScan => 'Scan';

  @override
  String get navSupplies => 'Supplies';

  @override
  String get navFirstAid => 'First aid';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get notSure => 'Not certain';

  @override
  String get needsInternet => 'Needs internet';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get sampleData => 'Sample data — not real locations';

  @override
  String homeStatus(String region) {
    return 'Works offline · Region pack: $region';
  }

  @override
  String get homeTitle => 'What do you need right now?';

  @override
  String get homeSub =>
      'Works without internet. Your location never leaves this phone.';

  @override
  String get homeFirstAidSub => 'Bleeding · Burns · Fractures · Breathing';

  @override
  String get homeNearestShelter => 'Nearest shelter';

  @override
  String get homeOpenMap => 'Open map →';

  @override
  String get homeNoShelter => 'No shelters in the saved region';

  @override
  String get homeAidTitle => 'Aid · Water';

  @override
  String get homeAidSub => 'Distribution points';

  @override
  String get homeUxoTitle => 'Unexploded ordnance';

  @override
  String get homeUxoSub => 'Don\'t touch, move away';

  @override
  String get homeMedTitle => 'Hospitals · Pharmacies';

  @override
  String get homeMedSub => 'Last verified info';

  @override
  String get homeFamilyTitle => 'Family meeting point';

  @override
  String get homeFamilySub => 'Your agreed place';

  @override
  String get homeWaterTitle => 'Safe drinking water';

  @override
  String get homeWaterSub => 'Boil · Bleach · Sunlight';

  @override
  String get homeKitTitle => 'Emergency bag';

  @override
  String get homeKitSub => 'What to take when you leave';

  @override
  String get sosAria => 'Rescue signal';

  @override
  String get langAria => 'Change language';

  @override
  String walkDistance(int minutes, String distance) {
    return '$minutes min walk · $distance';
  }

  @override
  String get dirN => 'North';

  @override
  String get dirNE => 'Northeast';

  @override
  String get dirE => 'East';

  @override
  String get dirSE => 'Southeast';

  @override
  String get dirS => 'South';

  @override
  String get dirSW => 'Southwest';

  @override
  String get dirW => 'West';

  @override
  String get dirNW => 'Northwest';

  @override
  String get locationFromGps => 'Distances from your GPS position';

  @override
  String get locationFallback =>
      'No GPS fix — distances from the region center';

  @override
  String get langTitle => 'Choose your language';

  @override
  String get langReady => 'Saved for offline use';

  @override
  String get langPending => '[Translation in progress]';

  @override
  String get langRtlPreview => 'RTL layout preview (text not translated)';

  @override
  String get continueLabel => 'Continue';

  @override
  String get mapTitle => 'Offline map';

  @override
  String mapArea(String area, String date) {
    return 'Saved area · $area · $date';
  }

  @override
  String get mapNoTiles =>
      'Map tiles for this region are not downloaded yet. Places and distances still work offline.';

  @override
  String get chipShelters => 'Shelters';

  @override
  String get chipAid => 'Aid';

  @override
  String get chipWater => 'Water';

  @override
  String get chipMedical => 'Medical';

  @override
  String get dangerZone => 'Reported danger';

  @override
  String get source => 'Source';

  @override
  String verified(String date) {
    return 'Verified $date';
  }

  @override
  String get compassGuide => 'Guide me by compass';

  @override
  String get compassTitle => 'Compass guide';

  @override
  String get compassHint => 'Hold the phone flat. Walk toward the arrow.';

  @override
  String compassUnavailable(String direction) {
    return 'No compass sensor on this device. Head $direction.';
  }

  @override
  String get compassArrived => 'You are within 30 m';

  @override
  String get scanTitle => 'Camera scan';

  @override
  String get scanMed => 'Medicine';

  @override
  String get scanPlant => 'Plant';

  @override
  String get scanWound => 'Wound';

  @override
  String get scanHintMed =>
      'Take a photo where the text on the bottle or box is clear.';

  @override
  String get scanHintPlant => 'Show the leaves, stem and flowers together.';

  @override
  String get scanHintWound =>
      'If it is bleeding, stop the bleeding first. Photograph the whole wound in good light.';

  @override
  String get scanTakePhoto => 'Take photo';

  @override
  String get scanFromGallery => 'Choose from photos';

  @override
  String get scanPrivacy =>
      'Photos are processed on this phone only and are never sent anywhere.';

  @override
  String get scanReading => 'Reading the text…';

  @override
  String get medTitle => 'Medicine info';

  @override
  String medConfidence(String level) {
    return 'Match: $level · Always compare with the text on the package';
  }

  @override
  String get confHigh => 'high';

  @override
  String get confMedium => 'medium';

  @override
  String get confLow => 'low';

  @override
  String get medWhatFor => 'What it\'s for';

  @override
  String get medMustKnow => 'Make sure you';

  @override
  String get medExpiry => 'Expiry date';

  @override
  String get medExpiryNote =>
      'Expired medicine may work less well. Check the date printed on the package.';

  @override
  String get medSaveToBox => 'Save to my medicine box';

  @override
  String get medSavedBox => 'My medicine box';

  @override
  String get medUnsure =>
      'If you are not sure, don\'t take it — ask a medical worker.';

  @override
  String get medNotFound => 'No match in the offline medicine list';

  @override
  String get medNotFoundHelp =>
      'Type the name or ingredient printed on the package.';

  @override
  String get medSearchHint => 'e.g. acetaminophen';

  @override
  String get medRecognized => 'Text found in the photo';

  @override
  String get medSampleDb =>
      'Sample medicine list (a few common medicines). The full list comes with the region pack.';

  @override
  String get plantTitle => 'Plant info';

  @override
  String get plantDontEat => 'Do not eat it';

  @override
  String get plantDontEatBody =>
      'A photo cannot tell whether a plant is safe to eat. Eating a poisonous plant by mistake can kill.';

  @override
  String get plantIdOnline =>
      'Plant identification needs internet and is not available yet. Even when it is, the result will only say what it might be — never that it is safe.';

  @override
  String get plantIfEaten => 'If someone ate or touched it and feels unwell';

  @override
  String get plantIfEatenBody =>
      'Vomiting, dizziness or difficulty breathing: get help right away. Bring the plant with you — it helps treatment.';

  @override
  String get woundTitle => 'Check the wound';

  @override
  String get woundPick =>
      'Which looks closest? You decide — the app does not diagnose.';

  @override
  String get woundConfirm => 'This is it';

  @override
  String get woundOther => 'Something else';

  @override
  String get woundGetHelp => 'Get help right away if';

  @override
  String get woundDoNow => 'What to do now';

  @override
  String get woundOpenGuide => 'Open the full step-by-step guide';

  @override
  String get suppliesTitle => 'Supplies';

  @override
  String get suppliesHave => 'What you have now';

  @override
  String get people => 'People with you';

  @override
  String peopleCount(int count) {
    return '$count';
  }

  @override
  String get drinkingWater => 'Drinking water';

  @override
  String liters(int value) {
    return '$value L';
  }

  @override
  String get foodMeals => 'Food · in meal portions';

  @override
  String get addFood => 'Add food';

  @override
  String get foodName => 'Food name';

  @override
  String get byWater => 'By water';

  @override
  String get byFood => 'By food';

  @override
  String days(String value) {
    return '$value days';
  }

  @override
  String get adviceWater =>
      'Water runs out first. Eat salty food and meat or fish only a little. Drink when thirsty — don\'t hold back — but cut down on activity that makes you sweat. (3 L per person per day)';

  @override
  String get adviceFood =>
      'Food runs out first. Eat what spoils fastest first and keep cans and dried food for later. (3 meals a day)';

  @override
  String get makeWater => 'Make safe drinking water';

  @override
  String get whatToEat => 'What can I eat with this?';

  @override
  String get waterTitle => 'Make safe drinking water';

  @override
  String get waterNever => 'No method makes this water safe';

  @override
  String get waterNeverBody =>
      'Water that smells of oil, fuel or chemicals, or has an odd color. Boiling does not remove poisons.';

  @override
  String get recipesTitle => 'Meals from what you have';

  @override
  String get filterAll => 'All';

  @override
  String get filterNoFire => 'No fire';

  @override
  String get filterNoWater => 'No water';

  @override
  String get recipeAvailable => 'Possible now';

  @override
  String recipeMissing(String items) {
    return 'Need: $items';
  }

  @override
  String servings(int count) {
    return 'Serves $count';
  }

  @override
  String get ingredients => 'Ingredients';

  @override
  String get howToMake => 'How to make';

  @override
  String get canSafety => 'Can safety';

  @override
  String get canSafetyBody =>
      'Do not eat from cans that are bulging, leaking or badly dented, or that foam or smell odd when opened. Never heat an unopened can on a fire — it can burst.';

  @override
  String get faTitle => 'First aid';

  @override
  String get faSearch => 'Search symptoms';

  @override
  String get faCameraCheck => 'Check a wound with the camera';

  @override
  String get faListen => 'Listen';

  @override
  String get faStop => 'Stop';

  @override
  String get faPrev => 'Back';

  @override
  String get faNext => 'Next step';

  @override
  String get faRestart => 'Start over';

  @override
  String faStepCounter(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get faReview => 'Medical text pending expert review before release.';

  @override
  String faSources(String sources) {
    return 'Sources: $sources';
  }

  @override
  String get uxoTitle => 'UXO safety';

  @override
  String get uxoWatch => 'Watch out for objects like these';

  @override
  String get sosTitle => 'Rescue signal';

  @override
  String get sosMyLocation => 'My location · GPS works without internet';

  @override
  String get sosReadOut => 'When you reach rescuers, read these numbers out.';

  @override
  String get sosNoFix => 'Getting GPS position…';

  @override
  String get sosSignals => 'SOS signal · by light or sound';

  @override
  String get sosTorch => 'Flashlight SOS';

  @override
  String get sosAlarm => 'Alarm sound';

  @override
  String get sosScreen => 'Screen flash';

  @override
  String get sosVibrate => 'Vibration signal';

  @override
  String get sosOn => 'On · tap to stop';

  @override
  String get sosOff => 'Tap to start';

  @override
  String get sosPattern =>
      '3 short · 3 long · 3 short. A whistle blown 3 times, repeated, is also understood as a call for help.';

  @override
  String get sosCheckFirst => 'Check around you first';

  @override
  String get sosCheckFirstBody =>
      'Where there is fighting, light and sound can reveal your position. Use them when rescuers are close.';

  @override
  String get emergencyNumbers => 'Emergency numbers';

  @override
  String get torchUnavailable => 'Flashlight not available on this device';

  @override
  String get familyTitle => 'Family meeting point';

  @override
  String get meet1 => 'Meeting point 1';

  @override
  String get meet2 => 'Meeting point 2 · if you can\'t reach point 1';

  @override
  String get placeName => 'Place name';

  @override
  String get placeHow => 'Address or how to get there';

  @override
  String get familyMembers => 'Family · viewable without internet';

  @override
  String get memberName => 'Name';

  @override
  String get memberContact => 'Contact';

  @override
  String get memberBlood => 'Blood type';

  @override
  String get memberAllergy => 'Allergies';

  @override
  String get memberMeds => 'Medicines';

  @override
  String get addMember => 'Add person';

  @override
  String get familyQr => 'Share with family by QR (no internet needed)';

  @override
  String get familyQrHelp =>
      'Let a family member photograph this code. It contains only what you typed on this screen.';

  @override
  String get prepareKit => 'Prepare the emergency bag →';

  @override
  String get kitTitle => 'Emergency bag';

  @override
  String kitProgress(int done, int total) {
    return '$done / $total ready';
  }

  @override
  String fireMinutes(int minutes) {
    return 'Fire $minutes min';
  }

  @override
  String waterMl(int ml) {
    return 'Water $ml ml';
  }
}
