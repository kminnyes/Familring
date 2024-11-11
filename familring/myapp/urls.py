from django.urls import path
from .views import delete_account, logout_view, add_event, get_family_events
# from .views import register, login, SaveQuestionView
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

from .views import (
    register, login, get_bucketlists, add_bucketlist, complete_bucketlist,
    get_profile, update_profile, send_family_invitation, check_invitation_status,
    respond_to_invitation, search_user, get_all_users, pending_family_request, get_csrf_token,
    save_question, create_family, save_answer, delete_family, family_members
)

urlpatterns = [
    # 회원관리
    path('register/', register, name='register'),
    path('get_csrf_token/', get_csrf_token, name='get_csrf_token'),  # CSRF 토큰 경로 추가
    path('login/', login, name='login'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # 버킷리스트
    path('bucket/', get_bucketlists, name='get_bucketlists'),
    path('bucket/add/', add_bucketlist, name='add_bucketlist'),
    path('bucket/complete/<int:bucket_id>/', complete_bucketlist, name='complete_bucketlist'),

    #프로필
    path('profile/', get_profile, name='get_profile'),
    path('profile/update/', update_profile, name='update_profile'),

    #가족 관련 url
    path('users/', get_all_users, name='get_all_users'),
    path('family/pending/', pending_family_request, name='pending_family_request'),
    path('user/search/', search_user, name='search_user'),
    path('family/create/', create_family, name='create_family'),
    path('family/invite/', send_family_invitation, name='send_family_invitation'),
    path('family/invitation/status/', check_invitation_status, name='check_invitation_status'),
    path('family/invitation/respond/', respond_to_invitation, name='respond_to_invitation'),
    path('family/<int:family_id>/delete/', delete_family, name='delete_family'),
    path('delete_account/', delete_account, name='delete_account'),
    path('family/members/', family_members, name='family_members'),
    path('family_list/', views.get_family_id, name='get_family_id'),

    # 질문 관련
    path('save_question/', save_question, name='save_question'),
    path('question_list/<int:family_id>/', views.question_list, name='question_list'),
    path('question_list/', views.question_list, name='question_list'),
    path('export_answers/', views.export_answers, name='export_answers'),
    path('process_json_data/', views.process_json_data, name='process_json_data'),
    path('generate_question/', views.generate_question, name='generate_question'),
    path('check_question_db', views.check_question_db, name='check_question_db'),

    #답변 관련
    path('save_answer/', save_answer, name='save_answer'),
    path('get_answer/<int:question_id>/<int:family_id>/', views.get_answer, name='get_answer'),
    path('check_answer_exists/<int:question_id>/<int:user_id>/', views.check_answer_exists, name='check_answer_exists'),
    path('update_answer/<int:answer_id>/', views.update_answer, name='update_answer'),


    #캘린더
    path('add-event/', add_event, name='add_event'),
    path('get-family-events/', get_family_events, name='get_family_events'),
    path('delete-event/', views.delete_event, name='delete_event'),
    path('update-event/', views.update_event, name='update_event'),
    path('get-today-events/', views.get_today_events, name='get_today_events'),
    path('family/members/', views.get_family_members, name='get_family_members'),

    #계정관련
    path('delete_account/', delete_account, name='delete_account'),
    path('logout/', logout_view, name='logout'),

    #폰트
    path('font-setting/', views.font_setting, name='font_setting'),

]