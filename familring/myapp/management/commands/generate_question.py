import os
from django.core.management.base import BaseCommand
from langchain_chroma import Chroma
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_core.prompts import ChatPromptTemplate

class Command(BaseCommand):
    help = "Generate a daily family-tailored question based on collective family answers"

    def handle(self, *args, **options):
        # API 키 설정
        os.environ["OPENAI_API_KEY"] = os.getenv("OPENAI_API_KEY")

        # 임베딩과 벡터 저장소 로드
        embedding = OpenAIEmbeddings(model="text-embedding-ada-002")
        vector_store = Chroma(collection_name="family_answers", persist_directory="./chroma_db", embedding_function=embedding)
        retriever = vector_store.as_retriever(search_kwargs={"k": 5})  # 최대 5개의 관련 답변을 검색

        # 질문 생성할 첫 쿼리 설정
        query = "어떤 일에 가장 큰 열정을 가지고 계시나요?"
        relevant_docs = retriever.invoke(query)

        # 관련 답변들을 요약하여 문맥으로 사용
        if relevant_docs:
            family_contexts = [doc.page_content for doc in relevant_docs[:5]]  # 최대 5개의 답변 사용
            self.stdout.write(f"검색된 관련 문서 수: {len(relevant_docs)}")
        else:
            self.stdout.write("관련 문서를 찾지 못했습니다.")
            return

        # 모델 초기화
        llm = ChatOpenAI(
            model="gpt-3.5-turbo",  # 또는 "gpt-4o-mini"로 변경 가능
            temperature=0.7,
            max_tokens=100
        )

        # 요약된 가족 답변을 기반으로 새로운 질문 생성
        context_text = " ".join(family_contexts)
        question_prompt = ChatPromptTemplate.from_template("""
        다음은 답변들입니다. 이 내용을 바탕으로 집단 전체를 대상으로 하는 새로운 질문을 생성해주세요.
        질문은 짧은 답변을 할 수 있는 형태 이지만, '네' 또는 '아니오'로 답할 수 없는 형태로 작성해 주세요.
        또한, 질문은 생각을 유도할 만한 질문이어야 합니다.

        가족 답변: {context}

        생성된 질문:
        """)

        # 질문 생성 및 출력
        formatted_prompt = question_prompt.format(context=context_text)
        response = llm.invoke(formatted_prompt)

        # 결과 출력
        self.stdout.write(f"가족 맞춤형 질문: {response.content}")
