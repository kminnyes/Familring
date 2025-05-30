### Familring
* 가족관계 개선을 위한 일일 질문 모바일 앱
* 2023.09 ~ 2024.11
* 예경민, 조성민, 손지연

 ### 사용 환경 및 기술
 * Python
 * Django
 * MySQL
 * Dart
 * Fultter
 * Android Studio
  * RAG(Retrieval-Augmented Generation)
  * ChatGPT 3.5 turbo api
  * AWS

### 주요 코드
* RAG
  
```
openai.api_key = os.getenv("OPENAI_API_KEY")

class Command(BaseCommand):
    help = "Generate a daily family-tailored question based on collective family answers"

    # 가족ID로 벡터 데이터베이스를 가져옴
    def add_arguments(self, parser):
        parser.add_argument('family_id', type=int, help="The ID of the family to generate question for")

    def handle(self, *args, **kwargs):
        family_id = kwargs['family_id']

        embedding = OpenAIEmbeddings(model="text-embedding-ada-002")
        vector_store = Chroma(
            collection_name=f"family_{family_id}_answers",
            persist_directory=f"./chroma_db/family_{family_id}",
            embedding_function=embedding
        )
        # 관련 문서 검색(top 5)
        retriever = vector_store.as_retriever(search_kwargs={"k": 5})

        query = "최근 가족의 관심사"
        relevant_docs = retriever.invoke(query)

        if relevant_docs:
            family_contexts = [doc.page_content for doc in relevant_docs]
            self.stdout.write(f"검색된 관련 문서의 수 {len(relevant_docs)}")
        else:
            self.stdout.write("관련 문서를 찾지 못했습니다.")
            return

        context_text = " ".join(family_contexts)

        # 질문 생성을 위한 프롬프트
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

        # 질문생성
        response = llm.invoke(prompt)
        generated_question = response.content.strip()

        self.stdout.write(f"가족 맞춤형 질문: {generated_question}")

        # DB에 질문 저장
        family = Family.objects.get(family_id=family_id)
        DailyQuestion.objects.create(question=generated_question, family=family)

  ```

### 구현 화면
* 메인화면, 마이페이지
<p float ="left">
  <img src="https://github.com/kminnyes/Familring/blob/main/README_img/%ED%99%88%20%ED%99%94%EB%A9%B4.png" width="170" height="340"/>
  <img src="https://github.com/kminnyes/Familring/blob/main/README_img/%EB%A7%88%EC%9D%B4%ED%8E%98%EC%9D%B4%EC%A7%80.png" width="170" height="340"/>
</p>
</br>

* 캘린더(오늘의 가족 일정, 버킷리스트)
<p float ="left">
  <img src="https://github.com/kminnyes/Familring/blob/main/README_img/%EC%BA%98%EB%A6%B0%EB%8D%94_%EB%B2%84%ED%82%B7%EB%A6%AC%EC%8A%A4%ED%8A%B8.png" width="170" height="340"/>
  <img src="https://github.com/kminnyes/Familring/blob/main/README_img/%EC%BA%98%EB%A6%B0%EB%8D%94.png" width="170" height="340"/>
  <img src="https://github.com/kminnyes/Familring/blob/main/README_img/%EB%B2%84%ED%82%B7%EB%A6%AC%EC%8A%A4%ED%8A%B8.png" width="170" height="340"/>
</p>
 </br>
 
* 질문
<p float ="left">
  <img src="https://github.com/kminnyes/Familring/blob/main/README_img/%EC%A7%88%EB%AC%B8%EC%95%8C%EB%A6%BC.png" width="170" height="340"/>
  <img src="https://github.com/kminnyes/Familring/blob/main/README_img/%EC%A7%88%EB%AC%B8.png" width="170" height="340"/>
  <img src="https://github.com/kminnyes/Familring/blob/main/README_img/%EC%A7%88%EB%AC%B8%EA%B8%B0%EB%A1%9D.png" width="170" height="340"/>
</p>
 </br>
