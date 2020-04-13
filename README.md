# ccube 장비 초기 설정 스크립트 

## 사용방법 
1. ccube_info 파일 내용 수정
```
PROJECT="measurement of urban infrasound sources"     ### 프로젝트 이름 설정 
INITDATE="2019/01/01"                                 ### 장비 설치 날짜 설정
SERIAL="AW7"                                          ### CCUBE 장비 시리얼 넘버 입력
CH_NUM="1"                                            ### Active Channels 개수 설정
P_AMPL="1"                                            ### Amplifier gain 설정 (증폭 안함 : 1)
LOCATION="Daejeon"                                    ### 설치 위치
S_RATE="100"                                          ### Samples rates
NET="KG"                                              ### seedlink Network code
LOC="00"                                              ### seedlink location code
STREAM="HD"                                           ### seedlink stream code
CHANNEL="F"                                           ### seedlink channel code
STATION="CC087"                                       ### seedlink station name
MSEED_SAVE="120"                                      ### miniseed 저장기간 설정
```
2. make_configuation_for_ccube.sh 실행
./make_configuration_for_ccube.sh
```
실행 시 아래와 같은 내용들이 생성 및 적용 됨.

1. dcube 연결 후  D_FILT_VALUE 획득
2. dcube logger 설정 ( 채널정보, 샘플, delay 설정)
3. dcube plugin 설정 (seedlink 구성을 위한 정보 입력됨)
4. seedlink 데이터 저장 설정 및 network 프로세스 모니터링 cron 생성
5. seedlink 기동 
6. ntp 기동
7. sysop 계정 생성

```
