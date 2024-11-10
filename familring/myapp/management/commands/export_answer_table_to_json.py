import json
from django.core.management.base import BaseCommand
from myapp.models import Answer
from datetime import datetime

class Command(BaseCommand):
    help = 'Exports new rows from Answer table to JSON file'

    def handle(self, *args, **options):
        # 기존 JSON 파일 읽기
        try:
            with open('answer.json', 'r', encoding='utf-8') as f:
                existing_data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            existing_data = []

        # 기존 데이터의 ID 목록 가져오기
        existing_ids = {item['id'] for item in existing_data}

        # 새 데이터 가져오기 (기존 ID에 없는 데이터)
        new_data = Answer.objects.exclude(id__in=existing_ids).values()

        # 새로운 데이터 추가
        for answer in new_data:
            answer_dict = dict(answer)
            if isinstance(answer_dict.get('created_at'), datetime):
                answer_dict['created_at'] = answer_dict['created_at'].isoformat()
            existing_data.append(answer_dict)

        # 업데이트된 JSON 파일 저장
        with open('answer.json', 'w', encoding='utf-8') as f:
            json.dump(existing_data, f, ensure_ascii=False, indent=4)

        self.stdout.write(self.style.SUCCESS('Successfully updated answer.json with new rows'))
