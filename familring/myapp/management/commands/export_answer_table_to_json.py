import os
import json
from django.core.management.base import BaseCommand
from myapp.models import Answer

class Command(BaseCommand):
    help = "Load JSON file from DB and save"

    def add_arguments(self, parser):
        parser.add_argument('family_id', type=int, help="The ID of the family to export answers for")

    def handle(self, *args, **kwargs):
        family_id = kwargs['family_id']
        json_file_path = f"family_{family_id}_answers.json"
        self.stdout.write(f"{json_file_path}에 JSON 파일을 생성하는 중입니다.")

        try:
            answers = Answer.objects.filter(family_id=family_id)
            if not answers.exists():
                self.stdout.write(self.style.WARNING("해당 family_id에 대한 답변이 없습니다."))
                return

            answer_data = [{"answer": answer.answer} for answer in answers]
            with open(json_file_path, "w", encoding="utf-8") as f:
                json.dump(answer_data, f, ensure_ascii=False, indent=4)
            self.stdout.write(f"JSON 파일 생성 완료 {json_file_path}")
        except Exception as e:
            self.stdout.write(f"JSON 파일 생성 중 오류 {e}")
