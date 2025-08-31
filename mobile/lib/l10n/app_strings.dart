// 앱에서 사용하는 모든 UI 텍스트를 관리하는 클래스입니다.
class AppStrings {
  // 로그인 화면
  static const String appName = 'R3';
  static const String appSlogan = '나의 러닝 기록이 자산이 되는 공간';
  static const String kakaoLogin = '카카오로 시작하기';
  static const String naverLogin = '네이버로 시작하기';
  static const String googleLogin = 'Google로 시작하기';
  // 프로필 화면
  static const String profileHeight = '키';
  static const String profileWeight = '몸무게';
  static const String heightHint = '키(cm)를 입력하세요';
  static const String weightHint = '몸무게(kg)를 입력하세요';

  // 하단 탭
  static const String tabHome = '홈';
  static const String tabRanking = '랭킹';
  static const String tabCreate = '생성';
  static const String tabExplore = '탐색';
  static const String tabMyInfo = '내 정보';

  // 플로팅 버튼 메뉴 (퀵 스타트)
  static const String quickStartRun = '러닝 시작';
  static const String quickStartWritePost = '추천 글쓰기';
  static const String quickStartWriteJournal = '일지 쓰기';
  static const String quickStartSavePhoto = '사진 저장';

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
  static const String openMyInfo = '내 정보 보기';
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
  static const String countdownGo = 'GO!';
  static const String runPause = '일시정지';
  static const String runResume = '다시시작';
  static const String runFinish = '종료';
  // 음성 안내 (TTS)
  // 음성 안내 (TTS)
  static const String ttsRunStarted = '러닝을 시작합니다.';
  static const String ttsRunPaused = '러닝을 일시정지합니다.';
  static const String ttsRunResumed = '러닝을 다시 시작합니다.';
  static const String ttsRunFinished = '러닝을 종료합니다.';

  static String ttsSplitNotification(int km, String totalTime, String avgPace) {
    return '거리 $km킬로미터, 총 시간 $totalTime, 평균 페이스 $avgPace';
  }

  static const String runFinishConfirmTitle = '러닝 종료';
  static const String runFinishConfirmContent = '현재 기록을 저장하시겠습니까?';
  static const String runSave = '저장';
  static const String runCancel = '취소';
  static const String longPressToFinish = '종료하려면 길게 누르세요';
  // 러닝 종료 확인
  static const String runExitConfirmTitle = '러닝 종료 확인';
  static const String runExitConfirmContent = '러닝을 정말로 종료하시겠습니까?';
  static const String runExitConfirmYes = '종료';
  static const String runExitConfirmNo = '계속하기';
  //러닝 결과 화면
  static const String viewDetails = '상세히 보기';
  // 구간 기록 페이지
  static const String splitsHeaderKm = '구간 (km)';
  static const String splitsHeaderPace = '페이스';
  static const String splitsHeaderTime = '시간';
  static const String runCadence = '케이던스';
  static const String runElevation = '고도 상승';
  static const String splitsEmpty = '1km 이상 달려 구간 기록을 확인해보세요.';
  // 구간 기록 페이지 헤더
  static const String splitsHeaderElevation = '고도';
  static const String splitsHeaderCadence = '케이던스';

  // 프로필 수정 화면
  static const String editProfileTitle = '프로필 수정';
  static const String saveChanges = '변경사항 저장';
  static const String nicknameHint = '새로운 닉네임을 입력하세요';
  static const String profileUpdateSuccess = '프로필이 성공적으로 업데이트되었습니다.';
  static const String profileUpdateFailed = '프로필 업데이트에 실패했습니다.';

  // 러닝 상세/수정
  static const String runNotes = '메모';
  static const String runDetailTitle = '러닝 상세 기록';
  static const String editRunTitle = '러닝 기록 수정';
  static const String edit = '수정하기';
  static const String delete = '삭제하기';
  static const String deleteConfirmTitle = '기록 삭제';
  static const String deleteConfirmContent =
      '이 러닝 기록을 정말로 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.';
  static const String runTitleLabel = '제목';
  static const String runNotesLabel = '메모';
  static const String runUpdateSuccess = '기록이 성공적으로 업데이트되었습니다.';
  static const String runUpdateFailed = '기록 업데이트에 실패했습니다.';
  static const String runDeleteSuccess = '기록이 삭제되었습니다.';
  static const String runDeleteFailed = '기록 삭제에 실패했습니다.';
}
