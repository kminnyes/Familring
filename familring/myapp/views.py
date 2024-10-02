from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import RegisterSerializer
from .models import CustomUser
from django.http import JsonResponse
from .models import DailyQuestion
import openai
from datetime import date

#회원가입 및 로그인 뷰
class RegisterView(APIView):
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(username=username, password=password)
        if user is not None:
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            })
        return Response({"error": "유효하지 않은 로그인 정보입니다."}, status=status.HTTP_401_UNAUTHORIZED)


#오늘의 질문
import logging
logger = logging.getLogger(__name__)

# OpenAI API Key 설정
openai.api_key = 'OPENAI_API_KEY'

class GenerateQuestionView(APIView):
    def get(self, request, *args, **kwargs):
        try:
            # 매번 새로운 질문을 생성
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": "Please generate a random daily question."}]
            )
            question = response['choices'][0]['message']['content'].strip()

            # 질문을 데이터베이스에 저장
            DailyQuestion.objects.create(question=question)
            return JsonResponse({'question': question})

        except Exception as e:
            # 에러 로그 출력
            print(f"Error generating question: {e}")
            return JsonResponse({'error': str(e)})



