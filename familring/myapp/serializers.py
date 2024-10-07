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
    family = FamilySerializer()

    class Meta:
        model = FamilyList
        fields = ['id', 'family', 'user']

class FamilyRequestSerializer(serializers.ModelSerializer):
    family = FamilySerializer(read_only=True)  # Family 정보를 포함

    class Meta:
        model = FamilyRequest
        fields = ['id', 'from_user', 'to_user', 'family', 'progress', 'created_at']
        read_only_fields = ['family', 'from_user', 'progress']