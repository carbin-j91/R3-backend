// 앱에서 사용하는 모든 UI 텍스트를 관리하는 클래스입니다.
class AppStrings {
  // 로그인 화면
  static const String appName = 'R3';
  static const String appSlogan = '나의 러닝 기록이 자산이 되는 공간';
  static const String kakaoLogin = '카카오로 시작하기';
  static const String naverLogin = '네이버로 시작하기';
  static const String googleLogin = 'Google로 시작하기';

  // ----> 아래 텍스트들을 추가합니다. <----

  // 하단 탭
  static const String tabHome = '홈';
  static const String tabRanking = '랭킹';
  static const String tabCreate = '생성';
  static const String tabExplore = '탐색';
  static const String tabMyInfo = '내 정보';

  // 생성(Create) 메뉴
  static const String createRun = '러닝';
  static const String createPost = '추천 글쓰기';
  static const String createJournal = '일지쓰기';
  static const String savePhoto = '사진저장';

  // 탐색 페이지 탭
  static const String exploreTabCourses = '도전 코스';
  static const String exploreTabHotplace = '러닝 핫플';
  static const String exploreTabTips = '러닝 팁';

  // 내 정보(My Info) 메뉴
  static const String myProfile = '나의 정보';
  static const String myRuns = '러닝 기록';
  static const String myPosts = '나의 글';
  static const String myAlbum = '내 앨범';

  static const String profileTitle = '나의 정보';
  static const String profileInfo = '프로필 정보';
  static const String profileNickname = '닉네임';
  static const String profileEmail = '이메일';
  static const String profileJoinDate = '가입일';
  static const String profileNotSet = '설정되지 않음';

  // 하단 탭
  static const String tabRecord = '기록'; // '크루'를 대체할 텍스트

  // 기록 페이지 메뉴
  static const String trainingLog = '훈련일지';

  // 기록 페이지 탭
  static const String recordTabRuns = '러닝기록';
  static const String recordTabJournal = '훈련일지';
  static const String recordTabAlbum = '앨범';

  // 하단 탭
  static const String tabAlbum = '앨범';

  // 홈 화면 탭
  static const String homeTabMain = '메인';
  static const String homeTabRanking = '랭킹';
  static const String homeTabAds = '광고';

  // 홈 화면 - 메인 탭
  static const String startRunning = '러닝 시작하기';
  static const String noticeArea = '공지사항이 표시될 공간입니다.';

  // 홈 화면 - 랭킹 탭
  static const String rankingArea = '랭킹 정보가 표시될 공간입니다.';

  // 홈 화면 - 광고 탭
  static const String adsArea = '광고가 2열로 표시될 공간입니다.';

  // 러닝 화면

  // 지도 준비 화면
  static const String mapReadyTitle = '러닝 준비';
  static const String startRunningFromMap = '여기서 러닝 시작';

  // 러닝 화면 UI
  static const String runDistance = '거리';
  static const String runTime = '시간';
  static const String runPace = '페이스';
  static const String runAvgPace = '평균 페이스';
  static const String runBPM = 'BPM';
  static const String runSplits = '구간';
  static const String runCalories = '칼로리';
  static const String runningArea = 'GPS 추적 기능이 구현될 화면입니다.';
  static const String locationPermissionDenied =
      '위치 권한이 거부되어 이 기능을 사용할 수 없습니다.';
  // 러닝 컨트롤
  static const String runPause = '일시정지';
  static const String runResume = '다시시작';
  static const String runFinish = '종료';
  static const String runFinishConfirmTitle = '러닝 종료';
  static const String runFinishConfirmContent = '현재 기록을 저장하시겠습니까?';
  static const String runSave = '저장';
  static const String runCancel = '취소';

  // 구간 기록 페이지
  static const String splitsHeaderKm = '구간 (km)';
  static const String splitsHeaderPace = '페이스';
  static const String splitsHeaderTime = '시간';
  static const String runElevation = '고도 상승';
  // 프로필 수정 화면
  static const String editProfileTitle = '프로필 수정';
  static const String saveChanges = '변경사항 저장';
  static const String nicknameHint = '새로운 닉네임을 입력하세요';
  static const String profileUpdateSuccess = '프로필이 성공적으로 업데이트되었습니다.';
  static const String profileUpdateFailed = '프로필 업데이트에 실패했습니다.';
}
