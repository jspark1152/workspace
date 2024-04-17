from transformers import BertForQuestionAnswering, BertTokenizer
import torch

#모델 : Stanford Q-A Dataset(SQUAD)를 기반으로 파인 튜닝된 모델
#model_name = 'bert-large-uncased-whole-word-masking-fine-tuned-squad'
#model_name에 이슈 > finetuned 로 수정
model_name = 'bert-large-uncased-whole-word-masking-finetuned-squad'

model = BertForQuestionAnswering.from_pretrained(model_name)

#토크나이저 다운로드
tokenizer = BertTokenizer.from_pretrained(model_name)

#[입력 전처리]
question = "What is the immune system?"
paragraph = "The immune system is a system of various biological structures and processes within an organism that protects against disease. To function properly, the immune system must detect a variety of substances known as pathogens, from viruses to parasites, and distinguish them from the healthy tissue of an organism."
#question = "면역 체계는 무엇입니까?"
#paragraph = "면역 체계는 질병으로부터 보호하는 유기체 내의 다양한 생물학적 구조와 과정의 시스템입니다. 제대로 기능하려면 면역 체계가 바이러스에서 기생충에 이르기까지 병원균으로 알려진 다양한 물질을 탐지하고 유기체의 건강한 조직과 구별해야 합니다."

#질문-단락 순으로 쌍을 짓기 때문에 아래와 같이 설정
question = '[CLS]' + question + '[SEP]'
paragraph = paragraph + '[SEP]'

#토큰화
question_tokens = tokenizer.tokenize(question)
paragraph_tokens = tokenizer.tokenize(paragraph)

#질문 및 단락 토큰을 연걸하고 input_ids로 변환
tokens = question_tokens + paragraph_tokens
input_ids = tokenizer.convert_tokens_to_ids(tokens)

#segment_ids 정의 : 질문 = 0, 단락 = 1
segment_ids = [0] * len(question_tokens) 
segment_ids += [1] * len(paragraph_tokens)

#len(input_ids) 와 len(segment_ids) 가 같아야 함
#print(len(input_ids), len(segment_ids))

#Tensor 변환
input_ids = torch.tensor([input_ids])
segment_ids = torch.tensor([segment_ids])

#[응답 얻기]
#각 토큰에 대한 시작 점수와 끝 점수를 반환하는 모델에 데이터 입력
output = model(input_ids, token_type_ids = segment_ids, return_dict=True)
start_scores = output['start_logits']
end_scores = output['end_logits']

#시작 점수가 가장 높은 토큰 인덱스 = start_index
#긑 점수가 가장 높은 토큰 인덱스 = end_index
start_index = torch.argmax(start_scores)
end_index = torch.argmax(end_scores)

#시작과 끝 범위를 출력
#print(start_index, end_index)
print(' '.join(tokens[start_index:end_index+1]))