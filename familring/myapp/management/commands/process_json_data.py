import os
import json
import openai
from django.core.management.base import BaseCommand
from langchain.text_splitter import CharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_chroma import Chroma
from langchain.schema import Document

openai.api_key = os.getenv("OPENAI_API_KEY")

class Command(BaseCommand):
    help = "Process JSON, split text, embed, and save to Chroma vector store"

    def add_arguments(self, parser):
        parser.add_argument('family_id', type=int, help="The ID of the family to process answers for")

    def handle(self, *args, **kwargs):
        family_id = kwargs['family_id']
        json_file_path = f"family_{family_id}_answers.json"

        # JSON 로드
        try:
            with open(json_file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            if not data:
                self.stdout.write("JSON 파일이 비어 있습니다.")
                return
            self.stdout.write(f"JSON 파일 로드 완료. 데이터 수 {len(data)}")
        except Exception as e:
            self.stdout.write(f"JSON 파일 로드 중 오류 발생 {e}")
            return

        # Document 객체 변환
        try:
            documents = [Document(page_content=item["answer"]) for item in data if "answer" in item]
            if not documents:
                self.stdout.write("변환된 Document 객체가 없습니다.")
                return
            self.stdout.write(f"Document 객체로 변환 완료. 변환된 문서의 수 {len(documents)}")
        except KeyError as e:
            self.stdout.write(f"데이터 변환 중 오류 발생 (KeyError) {e}")
            return

        # 텍스트 분할
        try:
            text_splitter = CharacterTextSplitter(chunk_size=250, chunk_overlap=50)
            split_docs = text_splitter.split_documents(documents)
            if not split_docs:
                self.stdout.write("텍스트 분할 결과가 없습니다.")
                return
            self.stdout.write(f"텍스트 분할 완료. 분할된 청크 수 {len(split_docs)}")
            for i, chunk in enumerate(split_docs[:5]):
                self.stdout.write(f"청크 {i + 1}: {chunk.page_content[:100]}...")
        except Exception as e:
            self.stdout.write(f"텍스트 분할 중 오류 발생 {e}")
            return

        # 임베딩 및 저장
        try:
            embedding = OpenAIEmbeddings(model="text-embedding-ada-002")
            vector_store = Chroma.from_documents(
                split_docs, embedding, collection_name=f"family_{family_id}_answers"
            )
            saved_doc_count = vector_store._collection.count()
            if saved_doc_count == 0:
                self.stdout.write("벡터 저장소가 비어 있습니다. 저장된 문서가 없습니다.")
                return
            self.stdout.write(f"임베딩 생성 및 Chroma 벡터 저장소 저장 완료. 저장된 문서의 수 {saved_doc_count}")
        except Exception as e:
            self.stdout.write(f"임베딩 생성 또는 벡터 저장소 저장 중 오류 발생 {e}")
