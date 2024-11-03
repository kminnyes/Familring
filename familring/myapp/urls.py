from django.urls import path
from .views import delete_account
from .views import register, login, add_event
from rest_framework_simplejwt.views import TokenRefreshView
from . import views


from .views import (
    register, login, get_family_bucketlist, add_bucketlist, complete_bucketlist,
    get_profile, update_profile, send_family_invitation, check_invitation_status,
    respond_to_invitation, search_user, get_all_users, pending_family_request, get_csrf_token
)

urlpatterns = [
    # 회원관리
    path('register/', register, name='register'),
    path('get_csrf_token/', get_csrf_token, name='get_csrf_token'),  # CSRF 토큰 경로 추가
    path('login/', login, name='login'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # 버킷리스트
    path('bucket/', get_family_bucketlist, name='get_family_bucketlist'),
    path('bucket/add/', add_bucketlist, name='add_bucketlist'),
    path('bucket/complete/<int:bucket_id>/', complete_bucketlist, name='complete_bucketlist'),

    path('profile/', get_profile, name='get_profile'),
    path('profile/update/', update_profile, name='update_profile'),

    path('users/', get_all_users, name='get_all_users'),
    path('family/pending/', pending_family_request, name='pending_family_request'),
    path('user/search/', search_user, name='search_user'),
    path('family/invite/', send_family_invitation, name='send_family_invitation'),
    path('family/invitation/status/', check_invitation_status, name='check_invitation_status'),
    path('family/invitation/respond/', respond_to_invitation, name='respond_to_invitation'),
    path('delete_account/', delete_account, name='delete_account'),
    path('add-event/', add_event, name='add_event'),
    path('get-family-events/', views.get_family_events, name='get_family_events'),
]