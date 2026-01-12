import { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { ArrowLeft, MapPin, Clock, TrendingUp, Calendar } from 'lucide-react';

export default function History() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const selectedWalkId = searchParams.get('walkId');

  const [selectedWalk, setSelectedWalk] = useState<number | null>(
    selectedWalkId ? parseInt(selectedWalkId) : null
  );

  const walks = [
    {
      id: 1,
      date: '2026-01-11',
      duration: '45分',
      distance: '2.3km',
      suggestions: 3,
      pathPoints: '20,80 35,65 50,50 65,40 80,30'
    },
    {
      id: 2,
      date: '2026-01-10',
      duration: '38分',
      distance: '1.9km',
      suggestions: 2,
      pathPoints: '15,70 30,60 45,50 60,45 75,40'
    },
    {
      id: 3,
      date: '2026-01-09',
      duration: '52分',
      distance: '2.8km',
      suggestions: 4,
      pathPoints: '25,85 40,70 55,55 70,45 85,35'
    }
  ];

  const selectedWalkData = walks.find((w) => w.id === selectedWalk);

  if (selectedWalk && selectedWalkData) {
    return (
      <div className="flex flex-col h-screen bg-white">
        {/* Header */}
        <div className="bg-white border-b border-gray-200 px-4 py-4 flex items-center gap-3 z-10">
          <button
            onClick={() => setSelectedWalk(null)}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
          >
            <ArrowLeft className="w-6 h-6 text-gray-700" />
          </button>
          <div className="flex-1">
            <h1 className="text-lg text-gray-900">{selectedWalkData.date}</h1>
            <p className="text-sm text-gray-600">
              {selectedWalkData.duration} • {selectedWalkData.distance}
            </p>
          </div>
          <button
            onClick={() => navigate(`/chat/${selectedWalk}`)}
            className="px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 transition-colors"
          >
            提案を見る
          </button>
        </div>

        {/* Map */}
        <div className="flex-1 relative bg-[#f2efe9]">
          <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" preserveAspectRatio="none">
            <defs>
              <pattern id="park-pattern" width="4" height="4" patternUnits="userSpaceOnUse">
                <rect width="4" height="4" fill="#c8e6c9"/>
                <circle cx="2" cy="2" r="0.5" fill="#81c784" opacity="0.3"/>
              </pattern>
            </defs>
            
            {/* Parks / Green spaces */}
            <rect x="10" y="10" width="25" height="20" fill="url(#park-pattern)" stroke="#81c784" strokeWidth="0.3"/>
            <rect x="65" y="50" width="30" height="25" fill="url(#park-pattern)" stroke="#81c784" strokeWidth="0.3"/>
            
            {/* Buildings */}
            <rect x="5" y="35" width="8" height="10" fill="#e0e0e0" stroke="#bdbdbd" strokeWidth="0.2"/>
            <rect x="15" y="35" width="6" height="12" fill="#eeeeee" stroke="#bdbdbd" strokeWidth="0.2"/>
            <rect x="23" y="33" width="10" height="14" fill="#e0e0e0" stroke="#bdbdbd" strokeWidth="0.2"/>
            <rect x="40" y="20" width="12" height="10" fill="#eeeeee" stroke="#bdbdbd" strokeWidth="0.2"/>
            <rect x="55" y="15" width="8" height="15" fill="#e0e0e0" stroke="#bdbdbd" strokeWidth="0.2"/>
            <rect x="45" y="35" width="10" height="8" fill="#e0e0e0" stroke="#bdbdbd" strokeWidth="0.2"/>
            <rect x="75" y="20" width="15" height="12" fill="#eeeeee" stroke="#bdbdbd" strokeWidth="0.2"/>
            <rect x="15" y="55" width="12" height="10" fill="#e0e0e0" stroke="#bdbdbd" strokeWidth="0.2"/>
            <rect x="30" y="60" width="8" height="12" fill="#eeeeee" stroke="#bdbdbd" strokeWidth="0.2"/>
            <rect x="42" y="58" width="10" height="9" fill="#e0e0e0" stroke="#bdbdbd" strokeWidth="0.2"/>
            
            {/* Major roads */}
            <rect x="0" y="29" width="100" height="3" fill="#ffffff" stroke="#d4d4d4" strokeWidth="0.2"/>
            <rect x="0" y="62" width="100" height="2.5" fill="#ffffff" stroke="#d4d4d4" strokeWidth="0.2"/>
            <rect x="38" y="0" width="3" height="100" fill="#ffffff" stroke="#d4d4d4" strokeWidth="0.2"/>
            <rect x="72" y="0" width="3.5" height="100" fill="#ffffff" stroke="#d4d4d4" strokeWidth="0.2"/>
            
            {/* Minor roads */}
            <rect x="0" y="48" width="100" height="1.5" fill="#ffffff" stroke="#e5e5e5" strokeWidth="0.1"/>
            <rect x="58" y="0" width="1.5" height="100" fill="#ffffff" stroke="#e5e5e5" strokeWidth="0.1"/>
            <rect x="22" y="0" width="1.5" height="100" fill="#ffffff" stroke="#e5e5e5" strokeWidth="0.1"/>
            
            {/* Road markings */}
            <line x1="0" y1="30.5" x2="100" y2="30.5" stroke="#f5f5f5" strokeWidth="0.3" strokeDasharray="2,1"/>
            <line x1="39.5" y1="0" x2="39.5" y2="100" stroke="#f5f5f5" strokeWidth="0.3" strokeDasharray="2,1"/>
            
            {/* Walking path */}
            <polyline
              points={selectedWalkData.pathPoints}
              fill="none"
              stroke="#3b82f6"
              strokeWidth="0.8"
              strokeLinecap="round"
              strokeLinejoin="round"
              opacity="0.9"
            />
            
            {/* Start marker */}
            <circle cx="20" cy="80" r="1.8" fill="#10b981" stroke="white" strokeWidth="0.4" />
            <text x="20" y="85" fontSize="3" textAnchor="middle" fill="#10b981" className="font-semibold">スタート</text>
            
            {/* End marker */}
            <circle cx="80" cy="30" r="1.8" fill="#ef4444" stroke="white" strokeWidth="0.4" />
            <text x="80" y="27" fontSize="3" textAnchor="middle" fill="#ef4444" className="font-semibold">ゴール</text>
          </svg>

          {/* Stats overlay */}
          <div className="absolute bottom-4 left-4 right-4 bg-white rounded-2xl p-4 shadow-lg">
            <div className="grid grid-cols-3 gap-4 text-center">
              <div>
                <Clock className="w-5 h-5 text-gray-400 mx-auto mb-1" />
                <div className="text-sm text-gray-600">時間</div>
                <div className="text-lg text-gray-900">{selectedWalkData.duration}</div>
              </div>
              <div>
                <TrendingUp className="w-5 h-5 text-gray-400 mx-auto mb-1" />
                <div className="text-sm text-gray-600">距離</div>
                <div className="text-lg text-gray-900">{selectedWalkData.distance}</div>
              </div>
              <div>
                <MapPin className="w-5 h-5 text-gray-400 mx-auto mb-1" />
                <div className="text-sm text-gray-600">提案</div>
                <div className="text-lg text-gray-900">{selectedWalkData.suggestions}件</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-4 py-4 flex items-center gap-3">
        <button
          onClick={() => navigate('/home')}
          className="p-2 hover:bg-gray-100 rounded-full transition-colors"
        >
          <ArrowLeft className="w-6 h-6 text-gray-700" />
        </button>
        <h1 className="text-xl text-gray-900">いままでの散歩</h1>
      </div>

      {/* Walk List */}
      <div className="p-4 space-y-3">
        {walks.map((walk) => (
          <button
            key={walk.id}
            onClick={() => setSelectedWalk(walk.id)}
            className="w-full bg-white rounded-xl p-4 shadow-sm hover:shadow-md transition-all text-left"
          >
            <div className="flex items-start gap-4">
              <div className="bg-blue-100 p-3 rounded-xl">
                <MapPin className="w-6 h-6 text-blue-600" />
              </div>
              
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-2">
                  <Calendar className="w-4 h-4 text-gray-400" />
                  <span className="text-gray-900">{walk.date}</span>
                </div>
                
                <div className="grid grid-cols-3 gap-3 text-sm">
                  <div>
                    <div className="text-gray-600">時間</div>
                    <div className="text-gray-900">{walk.duration}</div>
                  </div>
                  <div>
                    <div className="text-gray-600">距離</div>
                    <div className="text-gray-900">{walk.distance}</div>
                  </div>
                  <div>
                    <div className="text-gray-600">提案</div>
                    <div className="text-gray-900">{walk.suggestions}件</div>
                  </div>
                </div>
              </div>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}