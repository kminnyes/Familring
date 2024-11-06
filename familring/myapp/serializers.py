from rest_framework import serializers
from .models import User, BucketList, Family, FamilyRequest, FamilyList


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'password', 'username', 'email', 'nickname', 'is_active', 'is_staff', 'is_superuser', 'last_login']


# 버킷리스트 시리얼라이저
class BucketListSerializer(serializers.ModelSerializer):
    class Meta:
        model = BucketList
        fields = '__all__'

class FamilySerializer(serializers.ModelSerializer):
    class Meta:
        model = Family
        fields = ['family_id', 'family_name', 'date', 'user']

class FamilyListSerializer(serializers.ModelSerializer):
    family_name = serializers.CharField(source='family.family_name', read_only=True)  # Family 모델의 family_name 참조

    class Meta:
        model = FamilyList
        fields = ['id', 'family', 'user', 'family_name']

class FamilyRequestSerializer(serializers.ModelSerializer):
    family = FamilySerializer(read_only=True)  # Family 정보를 포함

    class Meta:
        model = FamilyRequest
        fields = ['id', 'from_user', 'to_user', 'family', 'progress', 'created_at']
        read_only_fields = ['family', 'from_user', 'progress']



#일정 시리얼라이저
from rest_framework import serializers
from .models import Event, Family

class EventSerializer(serializers.ModelSerializer):
    family_id = serializers.IntegerField(write_only=True, required=False)  # family_id를 입력받아 참조
    family_name = serializers.CharField(source='family.family_name', read_only=True)  # 가족 이름을 읽기 전용으로 추가

    class Meta:
        model = Event
        fields = ['event_type', 'nickname', 'event_content', 'start_date', 'end_date', 'family_id', 'family_name']

    def create(self, validated_data):
        # family_id를 validated_data에서 꺼내고, family 필드에 참조할 수 있도록 설정
        family_id = validated_data.pop('family_id', None)
        family = None
        if family_id:
            family = Family.objects.get(family_id=family_id)
        return Event.objects.create(family=family, **validated_data)

