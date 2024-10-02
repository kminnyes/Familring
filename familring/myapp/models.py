from django.contrib.auth.models import AbstractUser
from django.db import models

#사용자 모델 정의
class CustomUser(AbstractUser):
    nickname = models.CharField(max_length=50, unique=True)

#오늘의 질문 모델 정의
class DailyQuestion(models.Model):
    question = models.TextField()
    created_at_q = models.DateField(auto_now_add=True)
