// 사진 분석 (Claude API). 사용자가 직접 입력한 API 키로 브라우저에서 바로 호출합니다.
const AI_MODEL = 'claude-opus-5-5';
const SDK_URL = 'https://esm.sh/@anthropic-ai/sdk@0.131.0';

const SCAN_MODES = {
  medicine: {
    label: '약 · 의약품', emoji: '💊',
    hint: '약 포장, 약병 라벨, 알약을 선명하게 찍으세요. 글자가 보이면 정확도가 올라갑니다.',
    prompt: `사진 속 의약품을 식별하세요. 제품명, 주성분과 함량, 효능(무엇에 쓰는 약인지), 포장/라벨에 적힌 일반적인 복용법, 주의사항과 금기(임산부·소아·간/신장 질환·다른 약과의 병용 등), 보이는 경우 유효기간, 보관법을 정리하세요.
라벨 글자가 보이지 않는 알약만 있다면 각인·색·모양으로 후보를 제시하되 낮은 신뢰도로 표시하고, 확인되지 않은 약은 복용하지 말라고 안내하세요.
유효기간이 지났거나 변색·변형되었으면 경고하세요. 복용량은 라벨/일반적인 성인 기준만 제시하고 개인 처방을 대신하지 않는다고 밝히세요.`
  },
  plant: {
    label: '식물 · 약초 · 버섯', emoji: '🌿',
    hint: '잎 앞뒷면, 줄기, 꽃·열매, 뿌리가 보이게 여러 각도에서 찍으면 좋습니다.',
    prompt: `사진 속 식물(또는 버섯)을 식별하세요. 가장 가능성 높은 후보와 학명, 식별 근거가 된 특징, 혼동하기 쉬운 독성 식물(한국 자생종 기준), 식용·약용 여부와 전통적 용도, 섭취 시 준비 방법을 정리하세요.
매우 중요: 버섯은 사진만으로 절대 식용 판정을 하지 마세요(danger_level은 '위험' 또는 '불명'). 식물도 독초와 닮은 종이 있으면 '먹지 말 것'을 분명히 하세요. 확신이 없으면 confidence를 '낮음'으로 하고 섭취하지 말라고 하세요.`
  },
  wound: {
    label: '상처 · 부상', emoji: '🩹',
    hint: '밝은 곳에서 상처 전체가 보이게 찍으세요. 크기 비교용으로 동전이나 손가락을 옆에 두면 좋습니다.',
    prompt: `사진 속 상처나 부상을 응급처치 관점에서 평가하세요. 상처 종류(찰과상·열상·자상·화상 등급·물림 등), 추정 심각도, 지금 당장 해야 할 응급처치를 순서대로, 하지 말아야 할 것, 감염·합병증 징후, 병원/119가 필요한 기준을 정리하세요.
이는 진단이 아니라 재난 상황의 응급처치 보조입니다. 심한 출혈, 깊은 상처, 얼굴·관절·손 부위, 화상 범위가 넓음, 감염 징후가 보이면 call_emergency를 true로 하세요.`
  },
  other: {
    label: '기타 (물·음식·물건)', emoji: '🔎',
    hint: '물, 음식, 물건, 표지판, 위험물 등 무엇이든 찍어서 물어보세요.',
    prompt: `사진 속 대상을 재난·생존 상황 관점에서 분석하세요. 무엇인지, 생존에 어떻게 쓸 수 있는지, 안전한지(예: 물·음식의 상태, 위험물 여부), 주의사항을 정리하세요. 불발탄·위험물로 보이면 절대 만지지 말고 신고하라고 안내하세요.`
  }
};

const SYSTEM_PROMPT = `당신은 한국에서 전쟁·재난 상황에 처한 사람을 돕는 생존·응급처치 보조자입니다.
사용자는 병원이나 약국에 바로 갈 수 없는 상황일 수 있습니다. 실용적이고 구체적으로, 그러나 보수적으로 답하세요.
원칙:
- 모든 답은 한국어로, 짧은 문장과 행동 중심으로 작성합니다.
- 확실하지 않으면 확실하지 않다고 말하고 confidence를 낮게 둡니다. 추측을 사실처럼 말하지 않습니다.
- 생명이 걸린 판단(먹어도 되는지, 약을 먹어도 되는지)에서 의심스러우면 '하지 말 것' 쪽으로 안내합니다.
- 응급 상황이면 119(가능한 경우)와 가장 먼저 할 일을 맨 앞에 둡니다.
- 사진이 흐리거나 대상이 보이지 않으면 다시 찍는 방법을 안내합니다.
- related_guides에는 앱에 내장된 오프라인 가이드 중 관련 있는 것만 넣습니다.`;

function resultSchema() {
  return {
    type: 'object',
    additionalProperties: false,
    required: ['title', 'summary', 'confidence', 'danger_level', 'call_emergency', 'sections', 'warnings', 'related_guides'],
    properties: {
      title: { type: 'string', description: '식별 결과 이름 (예: 타이레놀정 500mg, 쑥, 손등 열상)' },
      summary: { type: 'string', description: '한두 문장 요약' },
      confidence: { type: 'string', enum: ['높음', '보통', '낮음'] },
      danger_level: { type: 'string', enum: ['안전', '주의', '위험', '불명'] },
      call_emergency: { type: 'boolean', description: '즉시 119나 의료진이 필요한지' },
      sections: {
        type: 'array',
        items: {
          type: 'object', additionalProperties: false, required: ['heading', 'items'],
          properties: { heading: { type: 'string' }, items: { type: 'array', items: { type: 'string' } } }
        }
      },
      warnings: { type: 'array', items: { type: 'string' } },
      related_guides: { type: 'array', items: { type: 'string', enum: GUIDE_IDS } }
    }
  };
}

// 이미지 → 최대 1568px JPEG base64
function resizeImage(file, max = 1568) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const url = URL.createObjectURL(file);
    img.onload = () => {
      const s = Math.min(1, max / Math.max(img.width, img.height));
      const c = document.createElement('canvas');
      c.width = Math.round(img.width * s);
      c.height = Math.round(img.height * s);
      c.getContext('2d').drawImage(img, 0, 0, c.width, c.height);
      URL.revokeObjectURL(url);
      const dataUrl = c.toDataURL('image/jpeg', 0.85);
      // 기록용 작은 썸네일
      const t = document.createElement('canvas');
      const ts = Math.min(1, 160 / Math.max(img.width, img.height));
      t.width = Math.round(img.width * ts); t.height = Math.round(img.height * ts);
      t.getContext('2d').drawImage(img, 0, 0, t.width, t.height);
      resolve({ base64: dataUrl.split(',')[1], preview: dataUrl, thumb: t.toDataURL('image/jpeg', 0.7) });
    };
    img.onerror = () => { URL.revokeObjectURL(url); reject(new Error('이미지를 읽을 수 없습니다')); };
    img.src = url;
  });
}

let sdkPromise = null;
function loadSdk() {
  if (!sdkPromise) sdkPromise = import(SDK_URL).then(m => m.default).catch(e => { sdkPromise = null; throw e; });
  return sdkPromise;
}

async function analyzePhoto({ apiKey, mode, base64, note }) {
  const Anthropic = await loadSdk();
  const client = new Anthropic({ apiKey, dangerouslyAllowBrowser: true });
  const m = SCAN_MODES[mode];
  const text = m.prompt + (note ? `\n\n사용자 메모: ${note}` : '');
  const response = await client.messages.create({
    model: AI_MODEL,
    max_tokens: 16000,
    system: SYSTEM_PROMPT,
    output_config: { effort: 'medium', format: { type: 'json_schema', schema: resultSchema() } },
    fallbacks: 'default',
    messages: [{
      role: 'user',
      content: [
        { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: base64 } },
        { type: 'text', text }
      ]
    }]
  }, { headers: { 'anthropic-beta': 'server-side-fallback-2026-07-01' } });

  if (response.stop_reason === 'refusal') throw new Error('이 사진은 분석할 수 없습니다. 다른 사진으로 다시 시도하세요.');
  if (response.stop_reason === 'max_tokens') throw new Error('응답이 너무 길어 잘렸습니다. 다시 시도하세요.');
  const textBlock = response.content.find(b => b.type === 'text');
  if (!textBlock) throw new Error('분석 결과가 비어 있습니다.');
  return JSON.parse(textBlock.text);
}

function aiErrorMessage(e) {
  const s = e?.status;
  if (!navigator.onLine) return '인터넷에 연결되어 있지 않습니다. 사진 분석은 온라인에서만 됩니다. 아래 오프라인 가이드를 이용하세요.';
  if (s === 401) return 'API 키가 올바르지 않습니다. 설정에서 키를 확인하세요.';
  if (s === 429) return '요청이 많습니다. 잠시 후 다시 시도하세요.';
  if (s >= 500) return 'AI 서버가 일시적으로 응답하지 않습니다. 잠시 후 다시 시도하세요.';
  if (e instanceof TypeError || /import|fetch|module/i.test(e?.message || '')) return '서버에 연결하지 못했습니다. 네트워크를 확인하세요.';
  return e?.message || '알 수 없는 오류';
}
