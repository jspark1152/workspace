#pip install nlp==0.4.0
#pip install transformers

from transformers import BertForSequenceClassification, BertTokenizerFast, Trainer, TrainingArguments
from nlp import load_dataset
import torch
import numpy as np

#[데이터셋과 모델 로딩하기]
#pip install gdown
#gdown https://drive.google.com/uc?id=11_M4ootuT7I1G0RlihcC0cA3Elqotlc-

dataset = load_dataset('csv', data_files='./imdbs.csv', split='train')
print(type(dataset))
#nlp.arrow_dataset.Dataset

#데이터셋 분할
dataset = dataset.train_test_split(test_size = 0.3)
print(dataset)
'''
{
'train': Dataset(features: {'text': Value(dtype='string', id=None),
'label': Value(dtype='int64', id=None)}, num_rows: 70), 
'test': Dataset(features: {'text': Value(dtype='string', id=None), 
'label': Value(dtype='int64', id=None)}, num_rows: 30)
}
'''

#학습/테스트 셋 생성
train_set = dataset['train']
test_set = dataset['test']

#Pretrained Model 다운로드
model = BertForSequenceClassification.from_pretrained('bert-base-uncased')
tokenizer = BertTokenizerFast.from_pretrained('bert-base-uncased')

#[데이터셋 전처리]
'''
입력 문장 'I love Paris' 에 대해 토크나이저는 다음을 수행
tokens = [ [CLS], I, love, Paris, [SEP] ]
토큰의 고유 ID가 다음과 같다고 가정
input_ids = [101, 1045, 2293, 3000, 102]
Segment ID 생성, 이는 문장 구별 용도
token_type_ids = [0, 0, 0, 0, 0]
토큰 길이를 5라고 가정하고 Attention Mask 생성
attention_mask = [1, 1, 1, 1, 1]
'''

#이러한 과정은 토크나이저에 문장을 입력하면 수행
print(tokenizer('I love Paris'))

#여러 문장을 전달하여 패딩 작업도 자동으로 수행 가능
#Padding을 True로 설정하고 Seq 최대 길이를 5로 설정
print(tokenizer(['I love Paris', 'birds fly', 'snow fall'], padding = True, max_length = 5))

def preprocess(data):
    return tokenizer(data['text'], padding=True, truncation=True)

#전처리 함수를 이용해 학습 및 테스트 셋을 전처리
train_set = train_set.map(preprocess, batched=True, batch_size=len(train_set))
#test_set = test_set.map(preprocess, batched=True, batch_size=len(test_set))

#print(train_set)