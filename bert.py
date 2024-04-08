from transformers import BertModel, BertTokenizer
import torch
#아래 코드로 모델 다운로드
model = BertModel.from_pretrained('bert-base-uncased')
#모델을 사전 학습하는데 사용된 토크나이저 다운로드
tokenizer = BertTokenizer.from_pretrained('bert-base-uncased')

sentence = 'I love Paris'
tokens = tokenizer.tokenize(sentence)
print(tokens)
#['i', 'love', 'paris']
tokens = ['[CLS]'] + tokens + ['[SEP]']
print(tokens)
#['[CLS]', 'i', 'love', 'paris', '[SEP]']

#토큰 길이를 7로 유지해야한다고 가정
tokens = tokens + ['[PAD]'] + ['[PAD]']
print(tokens)
#['[CLS]', 'i', 'love', 'paris', '[SEP]', '[PAD]', '[PAD]']

#Attention Mask 생성
attention_mask = [1 if i != '[PAD]' else 0 for i in tokens]
print(attention_mask)
#[1, 1, 1, 1, 1, 0, 0]

#Token ID 부여
token_ids = tokenizer.convert_tokens_to_ids(tokens)
print(token_ids)
#[101, 1045, 2293, 3000, 102, 0, 0]

#Tensor 변환
token_ids = torch.tensor(token_ids).unsqueeze(0)
attention_mask = torch.tensor(attention_mask).unsqueeze(0)

hidden_rep, cls_head = model(
  input_ids=token_ids,
  attention_mask=attention_mask,
  return_dict = False   # this is needed to get a tensor as result
)
#model 표현 방식이 Transformer 버전 업데이트 됨에 따라 변경 됨
print(hidden_rep.shape)
#torch.Size([1, 7, 768])
#이는 [batch_size, sequence_length, hidden_size]를 의미
#hidden_rep[0][0] = [CLS]의 표현 벡터
#hidden_rep[0][1] = I의 표현 벡터

#[CLS] 토큰의 표현 = cls_head
print(cls_head.shape)
#torch.Size([1, 768]), 이는 [batch_size, hidden_size]를 의미