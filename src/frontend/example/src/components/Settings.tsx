import { useNavigate } from 'react-router-dom';
import { ArrowLeft, User, Bell, MapPin, Shield, HelpCircle, LogOut, ChevronRight } from 'lucide-react';

interface SettingsProps {
  onLogout: () => void;
}

export default function Settings({ onLogout }: SettingsProps) {
  const navigate = useNavigate();

  const handleLogout = () => {
    if (confirm('ログアウトしますか?')) {
      onLogout();
      navigate('/login');
    }
  };

  const settingsGroups = [
    {
      title: 'アカウント',
      items: [
        { icon: User, label: 'プロフィール', value: '山田太郎' },
        { icon: Bell, label: '通知設定', value: 'オン' }
      ]
    },
    {
      title: 'プライバシー',
      items: [
        { icon: MapPin, label: '位置情報', value: '常に許可' },
        { icon: Shield, label: 'データ管理', value: '' }
      ]
    },
    {
      title: 'サポート',
      items: [
        { icon: HelpCircle, label: 'ヘルプ', value: '' }
      ]
    }
  ];

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
        <h1 className="text-xl text-gray-900">設定</h1>
      </div>

      {/* Settings Groups */}
      <div className="p-4 space-y-6">
        {settingsGroups.map((group, groupIndex) => (
          <div key={groupIndex}>
            <h2 className="text-sm text-gray-600 mb-3 px-2">
              {group.title}
            </h2>
            <div className="bg-white rounded-xl shadow-sm divide-y divide-gray-100">
              {group.items.map((item, itemIndex) => {
                const Icon = item.icon;
                return (
                  <button
                    key={itemIndex}
                    className="w-full px-4 py-4 flex items-center gap-3 hover:bg-gray-50 transition-colors first:rounded-t-xl last:rounded-b-xl"
                  >
                    <Icon className="w-5 h-5 text-gray-600" />
                    <span className="flex-1 text-left text-gray-900">
                      {item.label}
                    </span>
                    {item.value && (
                      <span className="text-sm text-gray-600">
                        {item.value}
                      </span>
                    )}
                    <ChevronRight className="w-5 h-5 text-gray-400" />
                  </button>
                );
              })}
            </div>
          </div>
        ))}

        {/* Logout Button */}
        <div className="pt-4">
          <button
            onClick={handleLogout}
            className="w-full bg-white text-red-600 rounded-xl px-4 py-4 shadow-sm hover:bg-red-50 transition-colors flex items-center justify-center gap-2"
          >
            <LogOut className="w-5 h-5" />
            <span>ログアウト</span>
          </button>
        </div>

        {/* Version */}
        <div className="text-center text-sm text-gray-400 pt-4">
          バージョン 1.0.0
        </div>
      </div>
    </div>
  );
}
