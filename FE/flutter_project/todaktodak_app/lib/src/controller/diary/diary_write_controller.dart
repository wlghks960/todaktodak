import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:test_app/src/controller/diary/diary_controller.dart';
import 'package:test_app/src/model/diary/post_chatbot_model.dart';
import 'package:test_app/src/model/diary/post_diary_add.dart';
import 'package:test_app/src/model/diary/selected_image.dart';
import 'package:test_app/src/services/chatbot/chatbot_services.dart';
import 'package:test_app/src/services/diary/post_diary_services.dart';

class DiaryWriteController extends GetxController {
  var isListening = false.obs;
  var speechText = "Press the Mic button and start speaking".obs;
  final SpeechToText? speechToText = SpeechToText();
  final FlutterTts flutterTts = FlutterTts();

  final PostDiaryAdd diaryModel = PostDiaryAdd();
  final storage = const FlutterSecureStorage();
  final RxString chatbotMessage = "".obs;

  var test = 0.obs;
  Timer? timer;
  final RxString diaryText = "".obs;
  RxBool isSelected = true.obs;
  final userId = "".obs;
  final RxList<SelectedImage> images = [
    SelectedImage(imagePath: "assets/images/happy.png"),
    SelectedImage(imagePath: "assets/images/embarr.png"),
    SelectedImage(imagePath: "assets/images/sad.png"),
    SelectedImage(imagePath: "assets/images/angry.png"),
    SelectedImage(imagePath: "assets/images/nomal.png"),
  ].obs;

  final RxList<SelectedImage> peopleImages = [
    SelectedImage(imagePath: "assets/images/family.png"),
    SelectedImage(imagePath: "assets/images/friends.png"),
    SelectedImage(imagePath: "assets/images/couple.png"),
    SelectedImage(imagePath: "assets/images/person.png"),
    SelectedImage(imagePath: "assets/images/solo.png"),
  ].obs;

  @override
  void onInit() async {
    final userIdValue = await storage.read(key: 'userId');
    print("목소리를 사용할 수 있을 거야 ${await flutterTts.getVoices}");
    userId(userIdValue);
    debounce(speechText, (_) => testChatbot(speechText.value),
        time: const Duration(seconds: 1));
    super.onInit();
  }

  speak(String text) async {
    await flutterTts.setLanguage("ko-KR");
    await flutterTts.setVoice({'name': 'Google 한국의', 'locale': 'ko-KR'});
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  void listen() async {
    if (!isListening.value) {
      bool available = await speechToText!.initialize(
        onStatus: (val) {},
        onError: (val) {},
      );
      if (available) {
        isListening.value = true;
        int lastTranscriptionTime = DateTime.now().millisecondsSinceEpoch;
        speechToText!.listen(
          onResult: (val) {
            speechText.value = val.recognizedWords;
            lastTranscriptionTime = DateTime.now().millisecondsSinceEpoch;
          },
          onSoundLevelChange: (level) {
            lastTranscriptionTime = DateTime.now().millisecondsSinceEpoch;
          },
        );
        Future.delayed(const Duration(seconds: 1));
        // 일정 시간 간격으로 종료 여부를 체크하는 타이머 설정
        Timer.periodic(const Duration(seconds: 1), (timer) {
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          if (currentTime - lastTranscriptionTime > 2000) {
            // 종료 시간 조건을 만족하면 음성 인식 종료
            isListening.value = false;

            speechToText!.stop();
            timer.cancel(); // 타이머 취소
          }
        });
      }
    } else {
      isListening.value = false;
      speechToText!.stop();
    }
  }

  testChatbot(String text) async {
    print(text);
    final PostChatBotModel model = PostChatBotModel(text: text);
    var data = await ChatbotServices().postText(model);
    print(data.returnText);
    speak(chatbotMessage(data.returnText));
  }

  void togglePeopleImage(int index) {
    // print(index);
    print(peopleImages[index]);
    peopleImages[index].isSelected = !peopleImages[index].isSelected!;
  }

  void toggleImage(int index) {
    // 이미지 선택 토글
    print(images[index]);
    images[index].isSelected = !images[index].isSelected!;
  }

  void changeDiaryText(String value) {
    diaryText(value);
  }

  void testChangeGradePoint(int index) {
    test.value = index;
    diaryModel.diaryScore = test.value;
    print(diaryModel.diaryScore);
    isSelected(!false);
  }

  void colorChangeIndex(int index) {}

  diaryWrite() {
    diaryModel.userId = int.parse(userId.value);

    if (diaryModel.diaryEmotionIdList == null ||
        diaryModel.diaryEmotionIdList != null) {
      diaryModel.diaryEmotionIdList = [];
    }
    for (int i = 0; i < images.length; i++) {
      if (images[i].isSelected == true) {
        diaryModel.diaryEmotionIdList!.add(i + 1);
      }
    }

    if (diaryModel.diaryMetIdList == null ||
        diaryModel.diaryMetIdList != null) {
      diaryModel.diaryMetIdList = [];
    }

    for (int i = 0; i < peopleImages.length; i++) {
      if (peopleImages[i].isSelected == true) {
        diaryModel.diaryMetIdList!.add(i + 1);
      }
    }
    if (diaryModel.diaryDetailLineEmotionCountList == null ||
        diaryModel.diaryDetailLineEmotionCountList != null) {
      diaryModel.diaryDetailLineEmotionCountList = [];
    }

    for (int i = 0; i < 5; i++) {
      diaryModel.diaryDetailLineEmotionCountList!.add(0);
    }
    diaryModel.diaryContent = diaryText.value;
    postDiary();
  }

  postDiary() async {
    try {
      var data = await PostDiaryServices().postDiaryAdd(diaryModel);
      if (data.state == 200) {
        DiaryController.to.getDiaryList();
        update();
        Get.offNamed("/dashboard");
        Get.snackbar("성공", "일기가 성공적으로 작성완료 하였습니다.");
      }
    } catch (e) {
      Get.snackbar("오류발생", "$e");
    }
  }
}
