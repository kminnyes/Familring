import json
import os
from django.core.management.base import BaseCommand
from langchain_community.document_loaders import JSONLoader
from langchain.text_splitter import CharacterTextSplitter
from langchain_community.embeddings import OpenAIEmbeddings
from langchain_community.vectorstores import Chroma
import openai

openai.api_key = os.getenv("OPENAI_API_KEY")

class Command(BaseCommand):
    help = "Load JSON file, split text, embed, and save to Chroma vector store"

    def handle(self, *args, **kwargs):
        # 1. JSON 파일 경로 설정
        json_file_path = os.path.join("answer.json")
        self.stdout.write(f"{json_file_path}에서 JSON 파일 로드 중...")

        # 2. JSONLoader 사용하여 문서 불러오기
        loader = JSONLoader(file_path=json_file_path, jq_schema=".", text_content=False)
        documents = loader.load()

        # 3. 텍스트 분할
        text_splitter = CharacterTextSplitter(chunk_size=500, chunk_overlap=50)
        split_docs = text_splitter.split_documents(documents)
        self.stdout.write("텍스트 분할 완료.")

        # 4. 임베딩 및 벡터 저장소 생성
        embedding = OpenAIEmbeddings(model="text-embedding-ada-002")
        vector_store = Chroma.from_documents(split_docs, embedding)
        self.stdout.write("임베딩 생성 및 Chroma 벡터 저장소 저장 완료.")

        # 5. 특정 주제에 대한 질문 생성 (예: 가장 빈도가 높은 주제에 대해 질문)
        topic = "취미"  # 주제 예시, 실제 분석된 주제를 기반으로 할 수 있음
        question = self.generate_question(topic)
        self.stdout.write(f"'{topic}' 주제에 기반한 생성 질문: {question}")

    def generate_question(self, topic):
        prompt = f"{topic}에 대한 새로운 질문을 생성해 주세요."
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "한국어로 짧고 흥미로운 질문을 생성하세요."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=50,
            temperature=0.7
        )
        return response['choices'][0]['message']['content'].strip()
