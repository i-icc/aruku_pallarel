import { useNavigate } from 'react-router-dom';
import { Play, History, Settings, MapPin, Clock, TrendingUp } from 'lucide-react';

export default function Home() {
  const navigate = useNavigate();

  const stats = [
    { label: '今月の散歩', value: '12回', icon: MapPin },
    { label: '総時間', value: '8.5時間', icon: Clock },
    { label: '総距離', value: '24.3km', icon: TrendingUp }
  ];

  const recentWalks = [
    { id: 1, date: '2026-01-11', duration: '45分', distance: '2.3km' },
    { id: 2, date: '2026-01-10', duration: '38分', distance: '1.9km' },
    { id: 3, date: '2026-01-09', duration: '52分', distance: '2.8km' }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white pb-20">
      <div className="px-6 pt-12 pb-6">
        <div className="flex justify-between items-start mb-8">
          <div>
            <h1 className="text-3xl text-gray-900 mb-2">
              こんにちは
            </h1>
            <p className="text-gray-600">
              今日も散歩に出かけましょう
            </p>
          </div>
          <button
            onClick={() => navigate('/settings')}
            className="p-3 rounded-full hover:bg-gray-100 transition-colors"
          >
            <Settings className="w-6 h-6 text-gray-600" />
          </button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-3 gap-3 mb-8">
          {stats.map((stat) => {
            const Icon = stat.icon;
            return (
              <div key={stat.label} className="bg-white rounded-2xl p-4 shadow-sm">
                <Icon className="w-5 h-5 text-blue-600 mb-2" />
                <div className="text-xl text-gray-900 mb-1">
                  {stat.value}
                </div>
                <div className="text-xs text-gray-600">
                  {stat.label}
                </div>
              </div>
            );
          })}
        </div>

        {/* Start Walking Button */}
        <button
          onClick={() => navigate('/walk')}
          className="w-full bg-blue-600 text-white rounded-2xl p-6 shadow-lg hover:bg-blue-700 transition-all hover:scale-[1.02] active:scale-[0.98] mb-8"
        >
          <div className="flex items-center justify-center gap-3">
            <Play className="w-8 h-8 fill-white" />
            <span className="text-xl">散歩を始める</span>
          </div>
        </button>

        {/* Recent Walks */}
        <div className="mb-6">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl text-gray-900">
              最近の散歩
            </h2>
            <button
              onClick={() => navigate('/history')}
              className="text-blue-600 text-sm flex items-center gap-1"
            >
              すべて見る
              <History className="w-4 h-4" />
            </button>
          </div>

          <div className="space-y-3">
            {recentWalks.map((walk) => (
              <button
                key={walk.id}
                onClick={() => navigate(`/history?walkId=${walk.id}`)}
                className="w-full bg-white rounded-xl p-4 shadow-sm hover:shadow-md transition-shadow text-left"
              >
                <div className="flex justify-between items-center">
                  <div>
                    <div className="text-gray-900 mb-1">
                      {walk.date}
                    </div>
                    <div className="text-sm text-gray-600">
                      {walk.duration} • {walk.distance}
                    </div>
                  </div>
                  <MapPin className="w-5 h-5 text-gray-400" />
                </div>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
