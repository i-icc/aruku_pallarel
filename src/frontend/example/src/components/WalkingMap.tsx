import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { MessageSquare, Square, Navigation, MapPin } from 'lucide-react';

export default function WalkingMap() {
  const navigate = useNavigate();
  const [duration, setDuration] = useState(0);
  const [distance, setDistance] = useState(0);
  const [currentPathIndex, setCurrentPathIndex] = useState(0);

  // Mock walking path - positions will be revealed over time
  const fullPath = [
    { x: 20, y: 80 },
    { x: 25, y: 75 },
    { x: 30, y: 70 },
    { x: 35, y: 68 },
    { x: 40, y: 65 },
    { x: 45, y: 60 },
    { x: 50, y: 55 },
    { x: 55, y: 52 },
    { x: 60, y: 48 },
    { x: 65, y: 43 },
    { x: 70, y: 38 },
    { x: 75, y: 35 },
  ];

  const currentPath = fullPath.slice(0, currentPathIndex + 1);
  const currentPosition = fullPath[currentPathIndex] || fullPath[0];

  // Mock suggested locations
  const suggestions = [
    {
      id: 1,
      name: 'おしゃれなカフェ',
      description: '散歩の休憩にぴったりです',
      position: { x: 60, y: 30 },
      showAt: 5 // Show after 5 path points
    }
  ];

  // Update duration every second
  useEffect(() => {
    const timer = setInterval(() => {
      setDuration((prev) => prev + 1);
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  // Update position every 10 seconds
  useEffect(() => {
    const positionTimer = setInterval(() => {
      setCurrentPathIndex((prev) => {
        if (prev < fullPath.length - 1) {
          setDistance((d) => d + 0.15); // Add ~150m each update
          return prev + 1;
        }
        return prev;
      });
    }, 10000); // Every 10 seconds

    return () => clearPositionTimer(positionTimer);
  }, []);

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const handleEndWalk = () => {
    if (confirm('散歩を終了しますか?')) {
      navigate('/home');
    }
  };

  const pathString = currentPath.map(p => `${p.x},${p.y}`).join(' ');

  const visibleSuggestions = suggestions.filter(s => currentPathIndex >= s.showAt);

  return (
    <div className="relative h-screen w-full bg-gray-100">
      {/* Mock Map Background */}
      <div className="h-full w-full relative overflow-hidden bg-[#f2efe9]">
        <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" preserveAspectRatio="none">
          <defs>
            {/* Park pattern */}
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
          {currentPath.length > 1 && (
            <polyline
              points={pathString}
              fill="none"
              stroke="#2563eb"
              strokeWidth="0.8"
              strokeLinecap="round"
              strokeLinejoin="round"
              opacity="0.9"
            />
          )}
          
          {/* Current position - pulsing circle */}
          <circle cx={currentPosition.x} cy={currentPosition.y} r="3" fill="#2563eb" opacity="0.2">
            <animate attributeName="r" from="3" to="6" dur="2s" repeatCount="indefinite" />
            <animate attributeName="opacity" from="0.2" to="0" dur="2s" repeatCount="indefinite" />
          </circle>
          <circle cx={currentPosition.x} cy={currentPosition.y} r="1.5" fill="#2563eb" stroke="white" strokeWidth="0.4" />
        </svg>

        {/* Suggestion markers */}
        {visibleSuggestions.map((suggestion) => (
          <div
            key={suggestion.id}
            className="absolute cursor-pointer group z-10"
            style={{
              left: `${suggestion.position.x}%`,
              top: `${suggestion.position.y}%`,
              transform: 'translate(-50%, -100%)'
            }}
            onClick={() => navigate('/chat/current')}
          >
            <div className="relative animate-bounce">
              <MapPin className="w-10 h-10 text-red-600 fill-red-600 drop-shadow-lg" />
              <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
                <div className="bg-white rounded-lg shadow-lg px-3 py-2 whitespace-nowrap">
                  <div className="font-semibold text-sm">{suggestion.name}</div>
                  <div className="text-xs text-gray-600">{suggestion.description}</div>
                </div>
              </div>
            </div>
          </div>
        ))}
        
        {/* Map labels */}
        <div className="absolute top-[12%] left-[18%] text-xs text-green-700 font-medium pointer-events-none">
          中央公園
        </div>
        <div className="absolute top-[62%] left-[78%] text-xs text-green-700 font-medium pointer-events-none">
          みどり公園
        </div>
        <div className="absolute top-[31%] left-[5%] text-xs text-gray-600 pointer-events-none">
          桜通り
        </div>
      </div>

      {/* Stats Overlay */}
      <div className="absolute top-0 left-0 right-0 p-4 bg-gradient-to-b from-black/30 to-transparent pointer-events-none">
        <div className="bg-white rounded-2xl p-4 shadow-lg pointer-events-auto">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <div className="text-sm text-gray-600 mb-1">時間</div>
              <div className="text-2xl text-gray-900">
                {formatDuration(duration)}
              </div>
            </div>
            <div>
              <div className="text-sm text-gray-600 mb-1">距離</div>
              <div className="text-2xl text-gray-900">
                {distance.toFixed(2)} km
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Current Location Button */}
      <button
        className="absolute right-4 top-32 bg-white p-3 rounded-full shadow-lg hover:bg-gray-50 transition-colors z-10"
        onClick={() => {}}
      >
        <Navigation className="w-6 h-6 text-blue-600" />
      </button>

      {/* Bottom Controls */}
      <div className="absolute bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-black/30 to-transparent">
        <div className="flex gap-3">
          <button
            onClick={() => navigate('/chat/current')}
            className="flex-1 bg-white text-gray-900 rounded-2xl py-4 shadow-lg hover:bg-gray-50 transition-colors flex items-center justify-center gap-2"
          >
            <MessageSquare className="w-5 h-5" />
            <span>チャット</span>
          </button>
          
          <button
            onClick={handleEndWalk}
            className="flex-1 bg-red-600 text-white rounded-2xl py-4 shadow-lg hover:bg-red-700 transition-colors flex items-center justify-center gap-2"
          >
            <Square className="w-5 h-5" />
            <span>終了</span>
          </button>
        </div>
      </div>
    </div>
  );
}