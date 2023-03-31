
from django.shortcuts import render
from rest_framework.decorators import api_view
from django.http import JsonResponse
from service.static.kogpt.kogpt import kogpt
from service.static.kobert.kobert import kobert
from service.static.emotion.emotion import emotion_bert
import json


def index(request):
    return render(request, "diarys/index.html")

@api_view(['POST',])
def answer(request):
    print(request)
    body_unicode = request.body.decode('utf-8')
    body = json.loads(body_unicode)
    input_text = body.get('text')
    if len(input_text) < 7:
        context ={
        'emotion': 0,
        'return_text': "더 말씀 주세요. 듣고 있답니다."
        }
        return JsonResponse(context)
    emotion = int(emotion_bert(input_text))
    try:
        if emotion == 0 or emotion == 1:
            return_text_kogpt = kogpt(input_text)
            return_text = return_text_kogpt + "!"
            status = "gpt"
        else:
            return_text_kogbert = kobert(input_text)
            return_text = return_text_kogbert
            status = "bert"
    except:
        return_text = "그러셨군요. "
        
    # print(emotion)
    # print(kogpt(input_text))
    # print(kobert(input_text))
    # print(f" 선택 받은자 : {status}")
    # print(f" 감정은 : {emotion}")
    
    context ={
        'emotion': emotion,
        'return_text': return_text
    }
    return JsonResponse(context)