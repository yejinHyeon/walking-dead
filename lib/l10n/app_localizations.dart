import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SURVIVOR'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScan;

  /// No description provided for @navSupplies.
  ///
  /// In en, this message translates to:
  /// **'Supplies'**
  String get navSupplies;

  /// No description provided for @navFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First aid'**
  String get navFirstAid;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @notSure.
  ///
  /// In en, this message translates to:
  /// **'Not certain'**
  String get notSure;

  /// No description provided for @needsInternet.
  ///
  /// In en, this message translates to:
  /// **'Needs internet'**
  String get needsInternet;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @sampleData.
  ///
  /// In en, this message translates to:
  /// **'Sample data — not real locations'**
  String get sampleData;

  /// No description provided for @homeStatus.
  ///
  /// In en, this message translates to:
  /// **'Works offline · Region pack: {region}'**
  String homeStatus(String region);

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you need right now?'**
  String get homeTitle;

  /// No description provided for @homeSub.
  ///
  /// In en, this message translates to:
  /// **'Works without internet. Your location never leaves this phone.'**
  String get homeSub;

  /// No description provided for @homeFirstAidSub.
  ///
  /// In en, this message translates to:
  /// **'Bleeding · Burns · Fractures · Breathing'**
  String get homeFirstAidSub;

  /// No description provided for @homeNearestShelter.
  ///
  /// In en, this message translates to:
  /// **'Nearest shelter'**
  String get homeNearestShelter;

  /// No description provided for @homeOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open map →'**
  String get homeOpenMap;

  /// No description provided for @homeNoShelter.
  ///
  /// In en, this message translates to:
  /// **'No shelters in the saved region'**
  String get homeNoShelter;

  /// No description provided for @homeAidTitle.
  ///
  /// In en, this message translates to:
  /// **'Aid · Water'**
  String get homeAidTitle;

  /// No description provided for @homeAidSub.
  ///
  /// In en, this message translates to:
  /// **'Distribution points'**
  String get homeAidSub;

  /// No description provided for @homeUxoTitle.
  ///
  /// In en, this message translates to:
  /// **'Unexploded ordnance'**
  String get homeUxoTitle;

  /// No description provided for @homeUxoSub.
  ///
  /// In en, this message translates to:
  /// **'Don\'t touch, move away'**
  String get homeUxoSub;

  /// No description provided for @homeMedTitle.
  ///
  /// In en, this message translates to:
  /// **'Hospitals · Pharmacies'**
  String get homeMedTitle;

  /// No description provided for @homeMedSub.
  ///
  /// In en, this message translates to:
  /// **'Last verified info'**
  String get homeMedSub;

  /// No description provided for @homeFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family meeting point'**
  String get homeFamilyTitle;

  /// No description provided for @homeFamilySub.
  ///
  /// In en, this message translates to:
  /// **'Your agreed place'**
  String get homeFamilySub;

  /// No description provided for @homeWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe drinking water'**
  String get homeWaterTitle;

  /// No description provided for @homeWaterSub.
  ///
  /// In en, this message translates to:
  /// **'Boil · Bleach · Sunlight'**
  String get homeWaterSub;

  /// No description provided for @homeKitTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency bag'**
  String get homeKitTitle;

  /// No description provided for @homeKitSub.
  ///
  /// In en, this message translates to:
  /// **'What to take when you leave'**
  String get homeKitSub;

  /// No description provided for @sosAria.
  ///
  /// In en, this message translates to:
  /// **'Rescue signal'**
  String get sosAria;

  /// No description provided for @langAria.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get langAria;

  /// No description provided for @walkDistance.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min walk · {distance}'**
  String walkDistance(int minutes, String distance);

  /// No description provided for @dirN.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get dirN;

  /// No description provided for @dirNE.
  ///
  /// In en, this message translates to:
  /// **'Northeast'**
  String get dirNE;

  /// No description provided for @dirE.
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get dirE;

  /// No description provided for @dirSE.
  ///
  /// In en, this message translates to:
  /// **'Southeast'**
  String get dirSE;

  /// No description provided for @dirS.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get dirS;

  /// No description provided for @dirSW.
  ///
  /// In en, this message translates to:
  /// **'Southwest'**
  String get dirSW;

  /// No description provided for @dirW.
  ///
  /// In en, this message translates to:
  /// **'West'**
  String get dirW;

  /// No description provided for @dirNW.
  ///
  /// In en, this message translates to:
  /// **'Northwest'**
  String get dirNW;

  /// No description provided for @locationFromGps.
  ///
  /// In en, this message translates to:
  /// **'Distances from your GPS position'**
  String get locationFromGps;

  /// No description provided for @locationFallback.
  ///
  /// In en, this message translates to:
  /// **'No GPS fix — distances from the region center'**
  String get locationFallback;

  /// No description provided for @langTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get langTitle;

  /// No description provided for @langReady.
  ///
  /// In en, this message translates to:
  /// **'Saved for offline use'**
  String get langReady;

  /// No description provided for @langPending.
  ///
  /// In en, this message translates to:
  /// **'[Translation in progress]'**
  String get langPending;

  /// No description provided for @langRtlPreview.
  ///
  /// In en, this message translates to:
  /// **'RTL layout preview (text not translated)'**
  String get langRtlPreview;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline map'**
  String get mapTitle;

  /// No description provided for @mapArea.
  ///
  /// In en, this message translates to:
  /// **'Saved area · {area} · {date}'**
  String mapArea(String area, String date);

  /// No description provided for @mapNoTiles.
  ///
  /// In en, this message translates to:
  /// **'Map tiles for this region are not downloaded yet. Places and distances still work offline.'**
  String get mapNoTiles;

  /// No description provided for @chipShelters.
  ///
  /// In en, this message translates to:
  /// **'Shelters'**
  String get chipShelters;

  /// No description provided for @chipAid.
  ///
  /// In en, this message translates to:
  /// **'Aid'**
  String get chipAid;

  /// No description provided for @chipWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get chipWater;

  /// No description provided for @chipMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get chipMedical;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Reported danger'**
  String get dangerZone;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified {date}'**
  String verified(String date);

  /// No description provided for @compassGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide me by compass'**
  String get compassGuide;

  /// No description provided for @compassTitle.
  ///
  /// In en, this message translates to:
  /// **'Compass guide'**
  String get compassTitle;

  /// No description provided for @compassHint.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone flat. Walk toward the arrow.'**
  String get compassHint;

  /// No description provided for @compassUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No compass sensor on this device. Head {direction}.'**
  String compassUnavailable(String direction);

  /// No description provided for @compassArrived.
  ///
  /// In en, this message translates to:
  /// **'You are within 30 m'**
  String get compassArrived;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera scan'**
  String get scanTitle;

  /// No description provided for @scanMed.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get scanMed;

  /// No description provided for @scanPlant.
  ///
  /// In en, this message translates to:
  /// **'Plant'**
  String get scanPlant;

  /// No description provided for @scanWound.
  ///
  /// In en, this message translates to:
  /// **'Wound'**
  String get scanWound;

  /// No description provided for @scanHintMed.
  ///
  /// In en, this message translates to:
  /// **'Take a photo where the text on the bottle or box is clear.'**
  String get scanHintMed;

  /// No description provided for @scanHintPlant.
  ///
  /// In en, this message translates to:
  /// **'Show the leaves, stem and flowers together.'**
  String get scanHintPlant;

  /// No description provided for @scanHintWound.
  ///
  /// In en, this message translates to:
  /// **'If it is bleeding, stop the bleeding first. Photograph the whole wound in good light.'**
  String get scanHintWound;

  /// No description provided for @scanTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get scanTakePhoto;

  /// No description provided for @scanFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from photos'**
  String get scanFromGallery;

  /// No description provided for @scanPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Photos are processed on this phone only and are never sent anywhere.'**
  String get scanPrivacy;

  /// No description provided for @scanReading.
  ///
  /// In en, this message translates to:
  /// **'Reading the text…'**
  String get scanReading;

  /// No description provided for @medTitle.
  ///
  /// In en, this message translates to:
  /// **'Medicine info'**
  String get medTitle;

  /// No description provided for @medConfidence.
  ///
  /// In en, this message translates to:
  /// **'Match: {level} · Always compare with the text on the package'**
  String medConfidence(String level);

  /// No description provided for @confHigh.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get confHigh;

  /// No description provided for @confMedium.
  ///
  /// In en, this message translates to:
  /// **'medium'**
  String get confMedium;

  /// No description provided for @confLow.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get confLow;

  /// No description provided for @medWhatFor.
  ///
  /// In en, this message translates to:
  /// **'What it\'s for'**
  String get medWhatFor;

  /// No description provided for @medMustKnow.
  ///
  /// In en, this message translates to:
  /// **'Make sure you'**
  String get medMustKnow;

  /// No description provided for @medExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get medExpiry;

  /// No description provided for @medExpiryNote.
  ///
  /// In en, this message translates to:
  /// **'Expired medicine may work less well. Check the date printed on the package.'**
  String get medExpiryNote;

  /// No description provided for @medSaveToBox.
  ///
  /// In en, this message translates to:
  /// **'Save to my medicine box'**
  String get medSaveToBox;

  /// No description provided for @medSavedBox.
  ///
  /// In en, this message translates to:
  /// **'My medicine box'**
  String get medSavedBox;

  /// No description provided for @medUnsure.
  ///
  /// In en, this message translates to:
  /// **'If you are not sure, don\'t take it — ask a medical worker.'**
  String get medUnsure;

  /// No description provided for @medNotFound.
  ///
  /// In en, this message translates to:
  /// **'No match in the offline medicine list'**
  String get medNotFound;

  /// No description provided for @medNotFoundHelp.
  ///
  /// In en, this message translates to:
  /// **'Type the name or ingredient printed on the package.'**
  String get medNotFoundHelp;

  /// No description provided for @medSearchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. acetaminophen'**
  String get medSearchHint;

  /// No description provided for @medRecognized.
  ///
  /// In en, this message translates to:
  /// **'Text found in the photo'**
  String get medRecognized;

  /// No description provided for @medSampleDb.
  ///
  /// In en, this message translates to:
  /// **'Sample medicine list (a few common medicines). The full list comes with the region pack.'**
  String get medSampleDb;

  /// No description provided for @plantTitle.
  ///
  /// In en, this message translates to:
  /// **'Plant info'**
  String get plantTitle;

  /// No description provided for @plantDontEat.
  ///
  /// In en, this message translates to:
  /// **'Do not eat it'**
  String get plantDontEat;

  /// No description provided for @plantDontEatBody.
  ///
  /// In en, this message translates to:
  /// **'A photo cannot tell whether a plant is safe to eat. Eating a poisonous plant by mistake can kill.'**
  String get plantDontEatBody;

  /// No description provided for @plantIdOnline.
  ///
  /// In en, this message translates to:
  /// **'Plant identification needs internet and is not available yet. Even when it is, the result will only say what it might be — never that it is safe.'**
  String get plantIdOnline;

  /// No description provided for @plantIfEaten.
  ///
  /// In en, this message translates to:
  /// **'If someone ate or touched it and feels unwell'**
  String get plantIfEaten;

  /// No description provided for @plantIfEatenBody.
  ///
  /// In en, this message translates to:
  /// **'Vomiting, dizziness or difficulty breathing: get help right away. Bring the plant with you — it helps treatment.'**
  String get plantIfEatenBody;

  /// No description provided for @woundTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the wound'**
  String get woundTitle;

  /// No description provided for @woundPick.
  ///
  /// In en, this message translates to:
  /// **'Which looks closest? You decide — the app does not diagnose.'**
  String get woundPick;

  /// No description provided for @woundConfirm.
  ///
  /// In en, this message translates to:
  /// **'This is it'**
  String get woundConfirm;

  /// No description provided for @woundOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get woundOther;

  /// No description provided for @woundGetHelp.
  ///
  /// In en, this message translates to:
  /// **'Get help right away if'**
  String get woundGetHelp;

  /// No description provided for @woundDoNow.
  ///
  /// In en, this message translates to:
  /// **'What to do now'**
  String get woundDoNow;

  /// No description provided for @woundOpenGuide.
  ///
  /// In en, this message translates to:
  /// **'Open the full step-by-step guide'**
  String get woundOpenGuide;

  /// No description provided for @suppliesTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplies'**
  String get suppliesTitle;

  /// No description provided for @suppliesHave.
  ///
  /// In en, this message translates to:
  /// **'What you have now'**
  String get suppliesHave;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People with you'**
  String get people;

  /// No description provided for @peopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String peopleCount(int count);

  /// No description provided for @drinkingWater.
  ///
  /// In en, this message translates to:
  /// **'Drinking water'**
  String get drinkingWater;

  /// No description provided for @liters.
  ///
  /// In en, this message translates to:
  /// **'{value} L'**
  String liters(int value);

  /// No description provided for @foodMeals.
  ///
  /// In en, this message translates to:
  /// **'Food · in meal portions'**
  String get foodMeals;

  /// No description provided for @addFood.
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get addFood;

  /// No description provided for @foodName.
  ///
  /// In en, this message translates to:
  /// **'Food name'**
  String get foodName;

  /// No description provided for @byWater.
  ///
  /// In en, this message translates to:
  /// **'By water'**
  String get byWater;

  /// No description provided for @byFood.
  ///
  /// In en, this message translates to:
  /// **'By food'**
  String get byFood;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{value} days'**
  String days(String value);

  /// No description provided for @adviceWater.
  ///
  /// In en, this message translates to:
  /// **'Water runs out first. Eat salty food and meat or fish only a little. Drink when thirsty — don\'t hold back — but cut down on activity that makes you sweat. (3 L per person per day)'**
  String get adviceWater;

  /// No description provided for @adviceFood.
  ///
  /// In en, this message translates to:
  /// **'Food runs out first. Eat what spoils fastest first and keep cans and dried food for later. (3 meals a day)'**
  String get adviceFood;

  /// No description provided for @makeWater.
  ///
  /// In en, this message translates to:
  /// **'Make safe drinking water'**
  String get makeWater;

  /// No description provided for @whatToEat.
  ///
  /// In en, this message translates to:
  /// **'What can I eat with this?'**
  String get whatToEat;

  /// No description provided for @waterTitle.
  ///
  /// In en, this message translates to:
  /// **'Make safe drinking water'**
  String get waterTitle;

  /// No description provided for @waterNever.
  ///
  /// In en, this message translates to:
  /// **'No method makes this water safe'**
  String get waterNever;

  /// No description provided for @waterNeverBody.
  ///
  /// In en, this message translates to:
  /// **'Water that smells of oil, fuel or chemicals, or has an odd color. Boiling does not remove poisons.'**
  String get waterNeverBody;

  /// No description provided for @recipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Meals from what you have'**
  String get recipesTitle;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterNoFire.
  ///
  /// In en, this message translates to:
  /// **'No fire'**
  String get filterNoFire;

  /// No description provided for @filterNoWater.
  ///
  /// In en, this message translates to:
  /// **'No water'**
  String get filterNoWater;

  /// No description provided for @recipeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Possible now'**
  String get recipeAvailable;

  /// No description provided for @recipeMissing.
  ///
  /// In en, this message translates to:
  /// **'Need: {items}'**
  String recipeMissing(String items);

  /// No description provided for @servings.
  ///
  /// In en, this message translates to:
  /// **'Serves {count}'**
  String servings(int count);

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @howToMake.
  ///
  /// In en, this message translates to:
  /// **'How to make'**
  String get howToMake;

  /// No description provided for @canSafety.
  ///
  /// In en, this message translates to:
  /// **'Can safety'**
  String get canSafety;

  /// No description provided for @canSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Do not eat from cans that are bulging, leaking or badly dented, or that foam or smell odd when opened. Never heat an unopened can on a fire — it can burst.'**
  String get canSafetyBody;

  /// No description provided for @faTitle.
  ///
  /// In en, this message translates to:
  /// **'First aid'**
  String get faTitle;

  /// No description provided for @faSearch.
  ///
  /// In en, this message translates to:
  /// **'Search symptoms'**
  String get faSearch;

  /// No description provided for @faCameraCheck.
  ///
  /// In en, this message translates to:
  /// **'Check a wound with the camera'**
  String get faCameraCheck;

  /// No description provided for @faListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get faListen;

  /// No description provided for @faStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get faStop;

  /// No description provided for @faPrev.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get faPrev;

  /// No description provided for @faNext.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get faNext;

  /// No description provided for @faRestart.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get faRestart;

  /// No description provided for @faStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String faStepCounter(int current, int total);

  /// No description provided for @faReview.
  ///
  /// In en, this message translates to:
  /// **'Medical text pending expert review before release.'**
  String get faReview;

  /// No description provided for @faSources.
  ///
  /// In en, this message translates to:
  /// **'Sources: {sources}'**
  String faSources(String sources);

  /// No description provided for @uxoTitle.
  ///
  /// In en, this message translates to:
  /// **'UXO safety'**
  String get uxoTitle;

  /// No description provided for @uxoWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch out for objects like these'**
  String get uxoWatch;

  /// No description provided for @sosTitle.
  ///
  /// In en, this message translates to:
  /// **'Rescue signal'**
  String get sosTitle;

  /// No description provided for @sosMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My location · GPS works without internet'**
  String get sosMyLocation;

  /// No description provided for @sosReadOut.
  ///
  /// In en, this message translates to:
  /// **'When you reach rescuers, read these numbers out.'**
  String get sosReadOut;

  /// No description provided for @sosNoFix.
  ///
  /// In en, this message translates to:
  /// **'Getting GPS position…'**
  String get sosNoFix;

  /// No description provided for @sosSignals.
  ///
  /// In en, this message translates to:
  /// **'SOS signal · by light or sound'**
  String get sosSignals;

  /// No description provided for @sosTorch.
  ///
  /// In en, this message translates to:
  /// **'Flashlight SOS'**
  String get sosTorch;

  /// No description provided for @sosAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm sound'**
  String get sosAlarm;

  /// No description provided for @sosScreen.
  ///
  /// In en, this message translates to:
  /// **'Screen flash'**
  String get sosScreen;

  /// No description provided for @sosVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibration signal'**
  String get sosVibrate;

  /// No description provided for @sosOn.
  ///
  /// In en, this message translates to:
  /// **'On · tap to stop'**
  String get sosOn;

  /// No description provided for @sosOff.
  ///
  /// In en, this message translates to:
  /// **'Tap to start'**
  String get sosOff;

  /// No description provided for @sosPattern.
  ///
  /// In en, this message translates to:
  /// **'3 short · 3 long · 3 short. A whistle blown 3 times, repeated, is also understood as a call for help.'**
  String get sosPattern;

  /// No description provided for @sosCheckFirst.
  ///
  /// In en, this message translates to:
  /// **'Check around you first'**
  String get sosCheckFirst;

  /// No description provided for @sosCheckFirstBody.
  ///
  /// In en, this message translates to:
  /// **'Where there is fighting, light and sound can reveal your position. Use them when rescuers are close.'**
  String get sosCheckFirstBody;

  /// No description provided for @emergencyNumbers.
  ///
  /// In en, this message translates to:
  /// **'Emergency numbers'**
  String get emergencyNumbers;

  /// No description provided for @torchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Flashlight not available on this device'**
  String get torchUnavailable;

  /// No description provided for @familyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family meeting point'**
  String get familyTitle;

  /// No description provided for @meet1.
  ///
  /// In en, this message translates to:
  /// **'Meeting point 1'**
  String get meet1;

  /// No description provided for @meet2.
  ///
  /// In en, this message translates to:
  /// **'Meeting point 2 · if you can\'t reach point 1'**
  String get meet2;

  /// No description provided for @placeName.
  ///
  /// In en, this message translates to:
  /// **'Place name'**
  String get placeName;

  /// No description provided for @placeHow.
  ///
  /// In en, this message translates to:
  /// **'Address or how to get there'**
  String get placeHow;

  /// No description provided for @familyMembers.
  ///
  /// In en, this message translates to:
  /// **'Family · viewable without internet'**
  String get familyMembers;

  /// No description provided for @memberName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get memberName;

  /// No description provided for @memberContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get memberContact;

  /// No description provided for @memberBlood.
  ///
  /// In en, this message translates to:
  /// **'Blood type'**
  String get memberBlood;

  /// No description provided for @memberAllergy.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get memberAllergy;

  /// No description provided for @memberMeds.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get memberMeds;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get addMember;

  /// No description provided for @familyQr.
  ///
  /// In en, this message translates to:
  /// **'Share with family by QR (no internet needed)'**
  String get familyQr;

  /// No description provided for @familyQrHelp.
  ///
  /// In en, this message translates to:
  /// **'Let a family member photograph this code. It contains only what you typed on this screen.'**
  String get familyQrHelp;

  /// No description provided for @prepareKit.
  ///
  /// In en, this message translates to:
  /// **'Prepare the emergency bag →'**
  String get prepareKit;

  /// No description provided for @kitTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency bag'**
  String get kitTitle;

  /// No description provided for @kitProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} ready'**
  String kitProgress(int done, int total);

  /// No description provided for @fireMinutes.
  ///
  /// In en, this message translates to:
  /// **'Fire {minutes} min'**
  String fireMinutes(int minutes);

  /// No description provided for @waterMl.
  ///
  /// In en, this message translates to:
  /// **'Water {ml} ml'**
  String waterMl(int ml);
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return LAr();
    case 'en':
      return LEn();
    case 'ko':
      return LKo();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
