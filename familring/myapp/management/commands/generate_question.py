import os
from django.core.management.base import BaseCommand
from langchain_community.vectorstores import Chroma
from langchain_openai.embeddings import OpenAIEmbeddings  # 최신 경로로 수정
from langchain_openai.chat_models import ChatOpenAI  # 최신 ChatOpenAI 클래스 사용
from langchain.prompts import PromptTemplate
from myapp.models import DailyQuestion, Family
import openai

openai.api_key = os.getenv("OPENAI_API_KEY")

class Command(BaseCommand):
    help = "Generate a daily family-tailored question based on collective family answers"

    def add_arguments(self, parser):
        parser.add_argument('family_id', type=int, help="The ID of the family to generate question for")

    def handle(self, *args, **kwargs):
        family_id = kwargs['family_id']

        # 임베딩과 벡터 저장소 로드
        embedding = OpenAIEmbeddings(model="text-embedding-ada-002")
        vector_store = Chroma(
            collection_name=f"family_{family_id}_answers",
            persist_directory=f"./chroma_db/family_{family_id}",
            embedding_function=embedding
        )
        retriever = vector_store.as_retriever(search_kwargs={"k": 5})

        # 관련 문서 검색
        query = "최근 가족의 관심사"
        relevant_docs = retriever.invoke(query)

        if relevant_docs:
            family_contexts = [doc.page_content for doc in relevant_docs]
            self.stdout.write(f"검색된 관련 문서 수: {len(relevant_docs)}")
        else:
            self.stdout.write("관련 문서를 찾지 못했습니다.")
            return

        # 질문 생성
        context_text = " ".join(family_contexts)
        prompt_template = PromptTemplate(
            input_variables=["context"],
            template=""" 
            다음은 구성원들의 답변입니다:
            {context}

            위 답변들을 바탕으로 집단에게 할 새로운 질문을 하나 생성해주세요.
            질문은 '네' 또는 '아니오'로 답할 수 없는 형태로 작성해 주세요.
            질문은 생각을 유도할 만한 질문이어야 합니다.
            질문은 30자내로 생성해 주세요.

            생성된 질문:
            """
        )

        prompt = prompt_template.format(context=context_text)
        llm = ChatOpenAI(model="gpt-3.5-turbo", temperature=0.7, max_tokens=100)

        # ChatOpenAI 호출하여 질문 생성
        response = llm.invoke(prompt)  # invoke 메서드 사용
        generated_question = response.content.strip()  # .content로 텍스트를 가져옴

        self.stdout.write(f"가족 맞춤형 질문: {generated_question}")

        # 질문을 데이터베이스에 저장
        family = Family.objects.get(family_id=family_id)
        DailyQuestion.objects.create(question=generated_question, family=family)
