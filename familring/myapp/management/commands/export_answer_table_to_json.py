import os
import json
from django.core.management.base import BaseCommand
from myapp.models import Answer
from langchain_community.document_loaders import JSONLoader
from langchain.text_splitter import CharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_chroma import Chroma
from langchain.schema import Document
import openai

openai.api_key = os.getenv("OPENAI_API_KEY")

class Command(BaseCommand):
    help = "Load JSON file, split text, embed, and save to Chroma vector store"

    def add_arguments(self, parser):
        parser.add_argument('family_id', type=int, help="The ID of the family to export answers for")

    def handle(self, *args, **kwargs):
        family_id = kwargs['family_id']
        json_file_path = f"family_{family_id}_answers.json"
        self.stdout.write(f"{json_file_path}에 JSON 파일을 생성 중...")

        # Step 1: Answer 데이터를 JSON 파일로 내보내기
        try:
            answers = Answer.objects.filter(family_id=family_id)
            if not answers.exists():
                self.stdout.write(self.style.WARNING("해당 family_id에 대한 답변이 없습니다."))
                return

            # Answer 모델에서 answer 필드만 가져오기
            answer_data = [{"answer": answer.answer} for answer in answers]

            # JSON 파일 생성
            with open(json_file_path, "w", encoding="utf-8") as f:
                json.dump(answer_data, f, ensure_ascii=False, indent=4)
            self.stdout.write(f"JSON 파일 생성 완료: {json_file_path}")

        except Exception as e:
            self.stdout.write(f"JSON 파일 생성 중 오류 발생: {e}")
            return

        # Step 2: JSON 파일을 Document 객체 리스트로 로드하기
        try:
            with open(json_file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            if not data:
                self.stdout.write("JSON 파일이 비어 있습니다.")
                return
            self.stdout.write(f"JSON 파일 로드 완료. 데이터 개수: {len(data)}")
        except Exception as e:
            self.stdout.write(f"JSON 파일 로드 중 오류 발생: {e}")
            return

        # Step 3: 데이터를 Document 객체로 변환
        try:
            documents = [Document(page_content=item["answer"]) for item in data if "answer" in item]
            if not documents:
                self.stdout.write("변환된 Document 객체가 없습니다.")
                return
            self.stdout.write(f"Document 객체로 변환 완료. 변환된 문서 개수: {len(documents)}")
        except KeyError as e:
            self.stdout.write(f"데이터 변환 중 오류 발생 (KeyError): {e}")
            return

        # Step 4: 텍스트 분할
        try:
            text_splitter = CharacterTextSplitter(chunk_size=250, chunk_overlap=50)
            split_docs = text_splitter.split_documents(documents)
            if not split_docs:
                self.stdout.write("텍스트 분할 결과가 없습니다.")
                return
            self.stdout.write(f"텍스트 분할 완료. 분할된 청크 수: {len(split_docs)}")
            for i, chunk in enumerate(split_docs[:5]):  # 처음 5개 청크만 출력
                self.stdout.write(f"청크 {i + 1}: {chunk.page_content[:100]}...")  # 일부만 출력
        except Exception as e:
            self.stdout.write(f"텍스트 분할 중 오류 발생: {e}")
            return

        # Step 5: 임베딩 생성 및 벡터 저장
        try:
            embedding = OpenAIEmbeddings(model="text-embedding-ada-002")
            vector_store = Chroma.from_documents(
                split_docs, embedding, collection_name=f"family_{family_id}_answers"
            )
            # Chroma 벡터 저장소가 잘 생성되었는지 확인
            saved_doc_count = vector_store._collection.count()
            if saved_doc_count == 0:
                self.stdout.write("벡터 저장소가 비어 있습니다. 저장된 문서가 없습니다.")
                return
            self.stdout.write(f"임베딩 생성 및 Chroma 벡터 저장소 저장 완료. 저장된 문서 수: {saved_doc_count}")
        except Exception as e:
            self.stdout.write(f"임베딩 생성 또는 벡터 저장소 저장 중 오류 발생: {e}")
