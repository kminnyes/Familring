from django.urls import path
from .views import RegisterView, LoginView, GenerateQuestionView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('generate_question/',GenerateQuestionView.as_view(), name='generate_question'),
]
