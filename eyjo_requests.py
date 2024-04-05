import requests
import time

def simulate_multiple_login_attempts(ip_address, uri_path, attempts=600):
    for i in range(attempts):
        print(f"Sending request #{i+1}")
        simulate_login_attempt(ip_address, uri_path)
        # 1초 대기
        #time.sleep(1)

def simulate_login_attempt(ip_address, uri_path):
    # HTTP 요청 시도
    try:
        response = requests.get(uri_path, headers={'X-Forwarded-For': ip_address})
        # 응답 확인
        if response.status_code == 200:
            print("로그인 시도 허용됨")
        elif response.status_code == 403:
            print("AWS WAF에 의해 차단됨")
        else:
            print("다른 상태 코드 반환됨:", response.status_code)
    except requests.RequestException as e:
        print("오류 발생:", e)

# IP 주소와 URI 경로 설정
ip_address = '3.35.53.87'
uri_path = 'http://dev.ey-jo.com/login.php'  # 로그인 페이지 URL로 변경

# 로그인 시도 시뮬레이션
simulate_multiple_login_attempts(ip_address, uri_path)