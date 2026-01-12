import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, ExternalLink, MapPin } from 'lucide-react';

export default function Chat() {
  const navigate = useNavigate();
  const { walkId } = useParams();

  const messages = [
    {
      id: 1,
      type: 'system',
      text: '散歩を開始しました。素敵な場所を見つけたら提案します!',
      time: '10:00'
    },
    {
      id: 2,
      type: 'suggestion',
      text: '近くに素敵なカフェがあります!',
      placeName: 'コーヒーハウス モク',
      placeDescription: '落ち着いた雰囲気で、窓際の席からは緑が見えます。散歩の休憩にぴったりです。',
      mapUrl: 'https://www.google.com/maps',
      streetViewUrl: 'https://www.google.com/maps',
      time: '10:15'
    },
    {
      id: 3,
      type: 'suggestion',
      text: '隠れた公園を発見しました!',
      placeName: '小さな森の公園',
      placeDescription: '地元の人しか知らない静かな公園。ベンチもあり、のんびりできます。',
      mapUrl: 'https://www.google.com/maps',
      streetViewUrl: 'https://www.google.com/maps',
      time: '10:30'
    }
  ];

  return (
    <div className="flex flex-col h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-4 py-4 flex items-center gap-3">
        <button
          onClick={() => navigate(-1)}
          className="p-2 hover:bg-gray-100 rounded-full transition-colors"
        >
          <ArrowLeft className="w-6 h-6 text-gray-700" />
        </button>
        <div>
          <h1 className="text-lg text-gray-900">提案チャット</h1>
          <p className="text-sm text-gray-600">
            {walkId === 'current' ? '散歩中' : '過去の散歩'}
          </p>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((message) => (
          <div key={message.id}>
            {message.type === 'system' && (
              <div className="flex justify-center">
                <div className="bg-gray-200 text-gray-700 text-sm px-4 py-2 rounded-full">
                  {message.text}
                </div>
              </div>
            )}

            {message.type === 'suggestion' && (
              <div className="bg-white rounded-2xl p-4 shadow-sm">
                <div className="flex items-start gap-3 mb-3">
                  <div className="bg-blue-100 p-2 rounded-full">
                    <MapPin className="w-5 h-5 text-blue-600" />
                  </div>
                  <div className="flex-1">
                    <div className="text-sm text-gray-600 mb-1">{message.text}</div>
                    <h3 className="text-lg text-gray-900 mb-1">
                      {message.placeName}
                    </h3>
                    <p className="text-sm text-gray-600">
                      {message.placeDescription}
                    </p>
                  </div>
                </div>

                <div className="flex gap-2">
                  <a
                    href={message.mapUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex-1 bg-blue-50 text-blue-600 text-sm py-2 px-3 rounded-lg hover:bg-blue-100 transition-colors flex items-center justify-center gap-2"
                  >
                    <span>地図を見る</span>
                    <ExternalLink className="w-4 h-4" />
                  </a>
                  <a
                    href={message.streetViewUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex-1 bg-green-50 text-green-600 text-sm py-2 px-3 rounded-lg hover:bg-green-100 transition-colors flex items-center justify-center gap-2"
                  >
                    <span>ストリートビュー</span>
                    <ExternalLink className="w-4 h-4" />
                  </a>
                </div>

                <div className="text-xs text-gray-400 mt-2 text-right">
                  {message.time}
                </div>
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Footer note */}
      {walkId !== 'current' && (
        <div className="bg-yellow-50 border-t border-yellow-100 p-4 text-center">
          <p className="text-sm text-yellow-800">
            過去の散歩の記録です（読み取り専用）
          </p>
        </div>
      )}
    </div>
  );
}
