from django.urls import path
from .views import delete_account, logout_view
# from .views import register, login, SaveQuestionView
from rest_framework_simplejwt.views import TokenRefreshView
from .import views
from .views import (
    register, login, get_bucketlists, add_bucketlist, complete_bucketlist,
    get_profile, update_profile, send_family_invitation, check_invitation_status,
    respond_to_invitation, search_user, get_all_users, pending_family_request, get_csrf_token,
    save_question, create_family,save_answer, add_event
)

urlpatterns = [
    # 회원관리
    path('register/', register, name='register'),
    path('get_csrf_token/', get_csrf_token, name='get_csrf_token'),  # CSRF 토큰 경로 추가
    path('login/', login, name='login'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # 버킷리스트
    path('bucket/', get_bucketlists, name='get_family_bucketlist'),
    path('bucket/add/', add_bucketlist, name='add_bucketlist'),
    path('bucket/complete/<int:bucket_id>/', complete_bucketlist, name='complete_bucketlist'),

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
    path('delete_account/', delete_account, name='delete_account'),

    # path('api/generate_question/', GenerateQuestionView.as_view(), name='generate_question'),
    path('save_question/', save_question, name='save_question'),

    #캘린더
    path('add-event/', add_event, name='add_event'),
    path('get-family-events/', views.get_family_events, name='get_family_events'),
    path('delete-event/', views.delete_event, name='delete_event'),

    #답변관련
    path('save_answer/', save_answer, name='save_answer'),

    #계정관련
    path('delete_account/', delete_account, name='delete_account'),
    path('logout/', logout_view, name='logout'),
]