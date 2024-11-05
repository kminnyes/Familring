from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import UserSerializer
from .models import User
from django.http import JsonResponse
from .models import DailyQuestion
import openai
from datetime import date
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import User, BucketList, Family, FamilyRequest, FamilyList
from .serializers import UserSerializer, BucketListSerializer, FamilySerializer, \
    FamilyRequestSerializer
from django.contrib.auth.hashers import make_password, check_password
from datetime import datetime
from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from django.middleware.csrf import get_token


@api_view(['GET'])
def get_csrf_token(request):
    csrf_token = get_token(request)
    return Response({'csrfToken': csrf_token})

# 회원가입
from rest_framework.permissions import AllowAny

@api_view(['POST'])
@permission_classes([AllowAny])  # 인증이 필요하지 않도록 설정
def register(request):
    data = request.data.copy()
    data['password'] = make_password(data['password'])
    serializer = UserSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    else:
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny


@api_view(['POST'])
@permission_classes([AllowAny])  # 누구나 접근 가능하게 설정
def login(request):
    data = request.data
    username = data.get('username')
    password = data.get('password')

    # 사용자 인증
    user = authenticate(request, username=username, password=password)
    if user is not None:
        # JWT 토큰 생성
        refresh = RefreshToken.for_user(user)
        # 사용자에 연결된 family 정보 가져오기
        family = Family.objects.filter(user_id=user).first()  # `user_id`로 수정
        family_id = family.family_id if family else None
        

        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user_id': user.id,
            'username': user.username,
            'family_id': family_id,
        }, status=status.HTTP_200_OK)
    else:
        return Response({'error': 'Invalid username or password'}, status=status.HTTP_400_BAD_REQUEST)

from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from .models import Family, FamilyList, BucketList
from .serializers import BucketListSerializer
from django.shortcuts import get_object_or_404

# 가족 및 개인 버킷리스트 가져오기
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_bucketlists(request):
    user = request.user
    family_list_entry = FamilyList.objects.filter(user=user).first()

    # 개인 버킷리스트
    personal_bucketlist = BucketList.objects.filter(user=user, family__isnull=True)

    # 가족 버킷리스트
    family_bucketlist = []
    if family_list_entry:
        family = family_list_entry.family
        family_bucketlist = BucketList.objects.filter(family=family, user__isnull=True)

    personal_serializer = BucketListSerializer(personal_bucketlist, many=True)
    family_serializer = BucketListSerializer(family_bucketlist, many=True)

    return Response(
        {
            'personal_bucket_list': personal_serializer.data,
            'family_bucket_list': family_serializer.data
        },
        status=status.HTTP_200_OK,
        content_type='application/json; charset=utf-8'
    )

# 버킷리스트 추가하기
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_bucketlist(request):
    user = request.user
    is_family_bucket = request.data.get('is_family_bucket', False)

    if is_family_bucket:
        # 가족 버킷리스트로 추가
        family_list_entry = FamilyList.objects.filter(user=user).first()
        if not family_list_entry:
            return Response({'error': 'No family associated with this user'}, status=status.HTTP_400_BAD_REQUEST)

        family = family_list_entry.family
        data = {
            'family': family.family_id,
            'bucket_title': request.data['bucket_title'],
            'is_completed': False,
        }
    else:
        # 개인 버킷리스트로 추가
        data = {
            'user': user.id,
            'bucket_title': request.data['bucket_title'],
            'is_completed': False,
        }

    serializer = BucketListSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from .models import BucketList
from django.shortcuts import get_object_or_404
from rest_framework import status

# 버킷리스트 완료 처리
@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def complete_bucketlist(request, bucket_id):
    user = request.user
    is_family_bucket = request.data.get('is_family_bucket', False)

    if is_family_bucket:
        # 가족 버킷리스트 완료 처리
        family_list_entry = FamilyList.objects.filter(user=user).first()
        if not family_list_entry:
            return Response({'error': 'No family associated with this user'}, status=status.HTTP_400_BAD_REQUEST)

        family = family_list_entry.family
        bucketlist = get_object_or_404(BucketList, id=bucket_id, family=family, user__isnull=True)
    else:
        # 개인 버킷리스트 완료 처리
        bucketlist = get_object_or_404(BucketList, id=bucket_id, user=user, family__isnull=True)

    bucketlist.is_completed = True
    bucketlist.save()
    return Response({"message": "버킷리스트가 완료되었습니다."}, status=status.HTTP_200_OK)

from rest_framework import status
from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import User
from .serializers import UserSerializer

@api_view(['GET'])
def get_profile(request):
    user = request.user
    serializer = UserSerializer(user)
    return Response(serializer.data)

@api_view(['PUT'])
def update_profile(request):
    user = request.user
    serializer = UserSerializer(user, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=400)

@api_view(['GET'])
def get_all_users(request):
    users = User.objects.all()
    serializer = UserSerializer(users, many=True)
    return Response(
        serializer.data,
        status=200,
        content_type='application/json; charset=utf-8'
    )

# 가족 생성 API
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_family(request):
    family_name = request.data.get('family_name')
    if not family_name:
        return Response({"error": "Family name is required"}, status=status.HTTP_400_BAD_REQUEST)

    # 새로운 가족 생성
    family = Family.objects.create(
        family_name=family_name,
        user=request.user
    )

    # 첫 번째 사용자를 가족 목록에 추가
    FamilyList.objects.create(family=family, user=request.user)

    return Response({"family_id": family.family_id, "family_name": family.family_name}, status=status.HTTP_201_CREATED)

# 사용자 검색 기능 (로그인한 사용자와 이미 가족 구성원인 사용자 제외)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_user(request):
    username = request.GET.get('username')
    if not username:
        return Response(
            {'error': 'Username parameter is required'},
            status=400,
            content_type='application/json; charset=utf-8'
        )

    # 검색된 사용자를 가져오되, 로그인한 사용자 및 이미 가족 구성원인 사용자를 제외
    users = User.objects.exclude(id=request.user.id)

    # 로그인한 사용자가 속한 가족 구성원을 가져오기
    family_members = FamilyList.objects.filter(family__user_id=request.user).values_list('user_id', flat=True)
    users = users.exclude(id__in=family_members)

    # 검색어와 일치하는 사용자 필터링
    users = users.filter(username__icontains=username)

    # 시리얼라이즈 후 응답
    serializer = UserSerializer(users, many=True)
    return Response(serializer.data, status=200)


# 가족 초대 요청 생성
@api_view(['POST'])
def send_family_invitation(request):
    data = request.data
    from_user = request.user
    to_user = get_object_or_404(User, id=data['to_user_id'])

    # from_user의 family를 가져오기
    try:
        family = Family.objects.get(user=from_user)  # Family와 User가 연결된 부분
    except Family.DoesNotExist:
        return Response({"error": "사용자의 가족 정보를 찾을 수 없습니다."}, status=status.HTTP_404_NOT_FOUND)

    # 이미 초대된 사용자인지 확인
    if FamilyRequest.objects.filter(from_user=from_user, to_user=to_user, family=family).exists():
        return Response({"error": "이미 가족 초대를 보냈습니다."}, status=status.HTTP_400_BAD_REQUEST)

    # 가족 초대 요청 생성
    FamilyRequest.objects.create(
        from_user=from_user,
        to_user=to_user,
        family=family,
        progress='진행중'
    )

    return Response({"message": "가족 초대 요청이 전송되었습니다."}, status=status.HTTP_201_CREATED)

# 가족 초대 요청 상태 확인
@api_view(['GET'])
def check_invitation_status(request):
    requests = FamilyRequest.objects.filter(to_user=request.user)
    response_data = []
    for request in requests:
        response_data.append({
            'from_user': request.from_user.nickname,
            'family_id': request.family.family_id,
            'progress': request.progress,
        })
    return Response(response_data, status=status.HTTP_200_OK)

@api_view(['GET'])
def pending_family_request(request):
    """
    진행 중인 가족 초대 요청을 가져오는 API.
    로그인한 사용자에게 도착한 초대 요청이 있는지 확인합니다.
    """
    try:
        # 현재 사용자가 받은 초대 요청 중 진행중인 요청 가져오기
        pending_requests = FamilyRequest.objects.filter(to_user_id=request.user, progress='진행중')

        if not pending_requests.exists():
            print("????")
            return Response({"message": "진행중인 가족 초대 요청이 없습니다."}, status=status.HTTP_200_OK)

        # 여러 초대 요청 중 첫 번째 요청만 처리
        pending_request = pending_requests.first()
        serializer = FamilyRequestSerializer(pending_request)
        return Response(serializer.data, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# 가족 초대 승인/거절
@api_view(['POST'])
def respond_to_invitation(request):
    data = request.data
    family_request = get_object_or_404(FamilyRequest, id=data['request_id'])

    if data['action'] == '승인':
        # FamilyList에 추가
        FamilyList.objects.create(
            family=family_request.family,
            user=request.user
        )
        family_request.progress = '승인'
        family_request.save()
        return Response({"message": "가족 초대가 승인되었습니다."}, status=status.HTTP_200_OK)
    elif data['action'] == '거절':
        family_request.progress = '거절'
        family_request.save()
        return Response({"message": "가족 초대가 거절되었습니다."}, status=status.HTTP_200_OK)

    return Response({"error": "잘못된 요청입니다."}, status=status.HTTP_400_BAD_REQUEST)


import json
#오늘의 질문 (gpt)
import logging
logger = logging.getLogger(__name__)
from django.views.decorators.csrf import csrf_exempt
# OpenAI API Key 설정
openai.api_key = 'OPENAI_API_KEY'
@csrf_exempt
def save_question(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        question_text = data.get('question', '')

        # 데이터베이스에 질문 저장
        question = DailyQuestion.objects.create(question=question_text)
        return JsonResponse({'message': 'Question saved successfully!', 'id': question.id})
    return JsonResponse({'error': 'Invalid request'}, status=400)


from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth import get_user_model

User = get_user_model()

# 회원탈퇴 API
@api_view(['DELETE'])
@permission_classes([IsAuthenticated])  # 인증된 사용자만 접근 가능
def delete_account(request):
    user = request.user
    user.delete()  # 사용자 계정 삭제
    return Response(status=204)

from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    refresh_token = request.data.get("refresh")
    if not refresh_token:
        return Response({"error": "Refresh token not provided"}, status=400)

    try:
        token = RefreshToken(refresh_token)
        token.blacklist()  # refresh 토큰을 블랙리스트에 등록하여 무효화
        return Response({"message": "로그아웃 성공"}, status=205)
    except Exception as e:
        print(f"로그아웃 실패 - 예외 발생: {e}")
        return Response({"error": f"로그아웃 실패: {str(e)}"}, status=400)



#캘린더 이벤트 생성하기
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .models import Event

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_event(request):
    data = request.data
    event_type = data.get('event_type')
    nickname = data.get('nickname')
    event_content = data.get('event_content')
    start_date = data.get('start_date')
    end_date = data.get('end_date')

    # 필수 필드 검증
    if not event_type:
        return Response({'error': 'Event type is required.'}, status=status.HTTP_400_BAD_REQUEST)
    if not event_content:
        return Response({'error': 'Event content is required.'}, status=status.HTTP_400_BAD_REQUEST)
    if not start_date:
        return Response({'error': 'Start date is required.'}, status=status.HTTP_400_BAD_REQUEST)
    if not end_date:
        return Response({'error': 'End date is required.'}, status=status.HTTP_400_BAD_REQUEST)

    # 날짜 형식 확인
    try:
        start_date = start_date  # datetime.date로 변환 (필요에 따라 파싱)
        end_date = end_date      # datetime.date로 변환
    except ValueError:
        return Response({'error': 'Invalid date format.'}, status=status.HTTP_400_BAD_REQUEST)

    # Event 인스턴스 생성 및 저장
    try:
        event = Event(
            event_type=event_type,
            nickname=nickname,
            event_content=event_content,
            start_date=start_date,
            end_date=end_date
        )
        event.save()
        return Response({'message': 'Event added successfully'}, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({'error': f'An error occurred: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



#캘린더 이벤트 가져오기
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .serializers import EventSerializer
from .models import Event

@api_view(['GET'])
def get_family_events(request):
    try:
        events = Event.objects.all()
        serializer = EventSerializer(events, many=True)

        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



#캘린더 이벤트 삭제하기
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Event

@api_view(['DELETE'])
def delete_event(request):
    try:
        # 요청에서 삭제할 기준 정보 받기
        event_type = request.data.get('event_type')
        nickname = request.data.get('nickname')
        event_content = request.data.get('event_content')
        start_date = request.data.get('start_date')
        end_date = request.data.get('end_date')

        # 필터링하여 조건에 맞는 모든 이벤트 삭제
        events = Event.objects.filter(
            event_type=event_type,
            nickname=nickname,
            event_content=event_content,
            start_date=start_date,
            end_date=end_date,
        )

        if events.exists():
            deleted_count, _ = events.delete()
            return Response({"message": f"{deleted_count} events deleted successfully."}, status=status.HTTP_200_OK)
        else:
            return Response({"error": "No matching events found."}, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)









