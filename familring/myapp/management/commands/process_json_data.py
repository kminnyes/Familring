import os
import json
from django.core.management.base import BaseCommand
from langchain.text_splitter import CharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.docstore.document import Document
import openai


openai.api_key = os.getenv("OPENAI_API_KEY")

class Command(BaseCommand):
    help = "Load JSON file, split text, embed, and save to Chroma vector store"

    def add_arguments(self, parser):
        parser.add_argument('family_id', type=int, help="The ID of the family to process data for")

    def handle(self, *args, **kwargs):
        family_id = kwargs['family_id']
        json_file_path = f"family_{family_id}_answers.json"
        self.stdout.write(f"{json_file_path}에서 JSON 파일 로드 중...")

        # JSON 파일 로드
        try:
            with open(json_file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            if len(data) == 0:
                self.stdout.write("JSON 파일이 비어 있습니다. 작업을 종료합니다.")
                return
            self.stdout.write(f"JSON 파일 로드 완료. 데이터 개수: {len(data)}")
        except Exception as e:
            self.stdout.write(f"JSON 파일 로드 중 오류 발생: {e}")
            return

        # 데이터를 Document 객체로 변환
        documents = [Document(page_content=item["answer"]) for item in data if "answer" in item]
        if len(documents) == 0:
            self.stdout.write("변환된 Document 객체가 없습니다. 작업을 종료합니다.")
            return
        self.stdout.write(f"Document 객체로 변환 완료. 변환된 문서 개수: {len(documents)}")

        # 텍스트 분할
        text_splitter = CharacterTextSplitter(chunk_size=250, chunk_overlap=50)
        split_docs = text_splitter.split_documents(documents)
        if len(split_docs) == 0:
            self.stdout.write("텍스트 분할 결과가 없습니다. 작업을 종료합니다.")
            return
        self.stdout.write(f"텍스트 분할 완료. 분할된 청크 수: {len(split_docs)}")

        # 임베딩 생성 및 벡터 저장
        try:
            embedding = OpenAIEmbeddings(model="text-embedding-ada-002")
            vector_store = Chroma.from_documents(
                split_docs,
                embedding,
                collection_name=f"family_{family_id}_answers",
                persist_directory=f"./chroma_db/family_{family_id}"
            )
            # 벡터 저장소의 문서 수 확인
            saved_doc_count = vector_store._collection.count()
            if saved_doc_count == 0:
                self.stdout.write("벡터 저장소가 비어 있습니다. 저장된 문서가 없습니다. 작업을 종료합니다.")
                return
            self.stdout.write(f"임베딩 생성 및 벡터 저장 완료. 저장된 문서 수: {saved_doc_count}")
        except Exception as e:
            self.stdout.write(f"임베딩 생성 또는 벡터 저장소 저장 중 오류 발생: {e}")
