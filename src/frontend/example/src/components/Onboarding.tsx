import { useState } from 'react';
import { MapPin, MessageSquare, Bell } from 'lucide-react';

interface OnboardingProps {
  onComplete: () => void;
}

export default function Onboarding({ onComplete }: OnboardingProps) {
  const [step, setStep] = useState(0);
  const [nickname, setNickname] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const features = [
    {
      icon: MapPin,
      title: '散歩を記録',
      description: 'あなたの散歩ルートを自動で記録します'
    },
    {
      icon: MessageSquare,
      title: 'AIが提案',
      description: '周辺のおすすめスポットをAIが提案'
    },
    {
      icon: Bell,
      title: 'リアルタイム通知',
      description: '新しい提案があればすぐに通知'
    }
  ];

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onComplete();
  };

  if (step < features.length) {
    const Feature = features[step].icon;
    return (
      <div className="flex flex-col items-center justify-between min-h-screen p-6 bg-gradient-to-b from-blue-50 to-white">
        <div className="flex-1 flex flex-col items-center justify-center">
          <div className="w-32 h-32 bg-blue-100 rounded-full flex items-center justify-center mb-8">
            <Feature className="w-16 h-16 text-blue-600" />
          </div>
          <h1 className="text-3xl mb-4 text-center text-gray-900">
            {features[step].title}
          </h1>
          <p className="text-lg text-center text-gray-600 max-w-sm">
            {features[step].description}
          </p>
        </div>
        
        <div className="w-full max-w-sm space-y-4">
          <div className="flex justify-center gap-2 mb-6">
            {features.map((_, index) => (
              <div
                key={index}
                className={`h-2 rounded-full transition-all ${
                  index === step ? 'w-8 bg-blue-600' : 'w-2 bg-gray-300'
                }`}
              />
            ))}
          </div>
          
          <button
            onClick={() => setStep(step + 1)}
            className="w-full py-4 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition-colors"
          >
            次へ
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center justify-center min-h-screen p-6 bg-gradient-to-b from-blue-50 to-white">
      <div className="w-full max-w-sm">
        <h1 className="text-3xl mb-2 text-gray-900">
          アカウント作成
        </h1>
        <p className="text-gray-600 mb-8">
          散歩を始めましょう
        </p>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm mb-2 text-gray-700">
              ニックネーム
            </label>
            <input
              type="text"
              value={nickname}
              onChange={(e) => setNickname(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="山田太郎"
              required
            />
          </div>
          
          <div>
            <label className="block text-sm mb-2 text-gray-700">
              メールアドレス
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="example@email.com"
              required
            />
          </div>
          
          <div>
            <label className="block text-sm mb-2 text-gray-700">
              パスワード
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="••••••••"
              required
              minLength={6}
            />
          </div>
          
          <button
            type="submit"
            className="w-full py-4 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition-colors mt-6"
          >
            登録する
          </button>
        </form>
      </div>
    </div>
  );
}
