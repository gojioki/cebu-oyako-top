'use client';

import { useMemo, useState } from 'react';
import { ArrowRight, Building2, Check, CircleDollarSign, MapPin, Plane, Users } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';

type Estimate = {
  school: number;
  travel: number;
  local: number;
  total: number;
};

const estimates: Record<'both' | 'child', Record<number, Estimate>> = {
  both: {
    1: { school: 24, travel: 20, local: 7, total: 51 },
    2: { school: 36, travel: 20, local: 7, total: 63 },
    4: { school: 59, travel: 20, local: 7, total: 86 },
  },
  child: {
    1: { school: 17, travel: 20, local: 3.5, total: 40.5 },
    2: { school: 27, travel: 20, local: 3.5, total: 50.5 },
    4: { school: 46, travel: 20, local: 3.5, total: 69.5 },
  },
};

function formatAmount(amount: number) {
  return `${amount}万円`;
}

function OptionButton({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      aria-pressed={active}
      onClick={onClick}
      className={`relative min-h-14 rounded-2xl border px-4 py-3 text-left text-sm font-bold transition-all focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-sky-200 ${
        active
          ? 'border-sky-700 bg-sky-50 text-sky-950 shadow-[0_6px_18px_rgba(2,92,135,0.10)]'
          : 'border-slate-200 bg-white text-slate-700 hover:border-sky-300 hover:bg-sky-50/50'
      }`}
    >
      {active && (
        <span className="absolute right-2 top-2 grid size-5 place-items-center rounded-full bg-sky-700 text-white">
          <Check className="size-3.5" strokeWidth={3} />
        </span>
      )}
      {children}
    </button>
  );
}

export default function Home() {
  const [weeks, setWeeks] = useState(4);
  const [parentTakesLessons, setParentTakesLessons] = useState(true);
  const estimate = useMemo(
    () => estimates[parentTakesLessons ? 'both' : 'child'][weeks],
    [weeks, parentTakesLessons]
  );
  const breakdown = [
    { label: '学校費用', amount: estimate.school, icon: Building2, tone: 'bg-sky-700', detail: '授業・2人部屋・食事' },
    { label: '渡航費用', amount: estimate.travel, icon: Plane, tone: 'bg-amber-500', detail: '親子2人の航空券・海外保険' },
    { label: '現地費用', amount: estimate.local, icon: MapPin, tone: 'bg-emerald-600', detail: '学校への現地支払い' },
  ];

  return (
    <main className="min-h-screen bg-[#f5f2ea] text-slate-900">
      <header className="border-b border-slate-200/80 bg-white/90">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-5 py-4 sm:px-8">
          <div>
            <p className="text-xs font-black tracking-[0.12em] text-sky-800">ぶっ飛びセブ島親子留学</p>
            <p className="mt-0.5 text-[11px] text-slate-500">トップページ見積り・改善モック</p>
          </div>
          <span className="rounded-full border border-amber-300 bg-amber-50 px-3 py-1.5 text-xs font-bold text-amber-800">検討用プロトタイプ</span>
        </div>
      </header>

      <section className="relative overflow-hidden px-5 py-10 sm:px-8 sm:py-14">
        <div className="absolute -right-24 -top-20 size-72 rounded-full bg-amber-300/20 blur-3xl" />
        <div className="absolute -left-24 top-64 size-72 rounded-full bg-sky-300/20 blur-3xl" />

        <div className="relative mx-auto max-w-6xl">
          <div className="mb-8 max-w-3xl">
            <div className="mb-3 flex items-center gap-2 text-sm font-black text-sky-800">
              <CircleDollarSign className="size-5" />
              2つ選ぶだけ、約20秒
            </div>
            <h1 className="text-3xl font-black leading-tight tracking-tight text-slate-950 sm:text-5xl">
              セブ島親子留学、<br className="sm:hidden" />うちなら総額いくら？
            </h1>
            <p className="mt-4 max-w-2xl text-sm leading-7 text-slate-600 sm:text-base">
              親1人＋子ども1人の親子留学を基準に、学校費用だけでなく、渡航費用と現地費用まで含めた総額の目安を表示します。
            </p>
          </div>

          <div className="grid items-start gap-6 lg:grid-cols-[1.06fr_.94fr]">
            <Card className="border-0 bg-white py-0 shadow-[0_18px_60px_rgba(15,23,42,0.08)] ring-1 ring-slate-200">
              <CardContent className="space-y-8 p-5 sm:p-8">
                <div className="flex items-center justify-between gap-4 rounded-2xl border border-sky-100 bg-sky-50 px-4 py-4 sm:px-5">
                  <div>
                    <p className="text-xs font-black tracking-[0.08em] text-sky-700">STANDARD MODEL</p>
                    <p className="mt-1 text-base font-black text-slate-950">親1人＋子ども1人</p>
                    <p className="mt-1 text-xs text-slate-500">親1人＋子ども1人／子どもは受講／宿泊・食事付き</p>
                  </div>
                  <Users className="size-8 shrink-0 text-sky-700" />
                </div>

                <fieldset>
                  <legend className="mb-4 flex items-center gap-3 text-base font-black">
                    <span className="grid size-8 place-items-center rounded-full bg-sky-800 text-sm text-white">1</span>
                    何週間行く？
                  </legend>
                  <div className="grid grid-cols-3 gap-2">
                    {[1, 2, 4].map((value) => (
                      <OptionButton key={value} active={weeks === value} onClick={() => setWeeks(value)}>
                        <span className="block text-center text-base">{value}週</span>
                      </OptionButton>
                    ))}
                  </div>
                </fieldset>

                <fieldset>
                  <legend className="mb-4 flex items-center gap-3 text-base font-black">
                    <span className="grid size-8 place-items-center rounded-full bg-sky-800 text-sm text-white">2</span>
                    親も授業を受ける？
                  </legend>
                  <div className="grid grid-cols-2 gap-2">
                    <OptionButton active={parentTakesLessons} onClick={() => setParentTakesLessons(true)}>
                      <span className="block text-center">受ける</span>
                      <span className="mt-1 block text-center text-xs font-medium text-slate-500">親子2人とも受講</span>
                    </OptionButton>
                    <OptionButton active={!parentTakesLessons} onClick={() => setParentTakesLessons(false)}>
                      <span className="block text-center">受けない</span>
                      <span className="mt-1 block text-center text-xs font-medium text-slate-500">子どもだけ受講</span>
                    </OptionButton>
                  </div>
                </fieldset>

                <div className="rounded-2xl bg-slate-50 px-4 py-3 text-xs leading-5 text-slate-500">
                  ※表示金額は親1人＋子ども1人の目安です。人数、受講者、滞在時期、宿泊条件によって金額は変わります。
                </div>
              </CardContent>
            </Card>

            <aside className="lg:sticky lg:top-6">
              <Card className="overflow-hidden border-0 bg-slate-950 py-0 text-white shadow-[0_24px_80px_rgba(15,23,42,0.24)] ring-0">
                <div className="border-b border-white/10 bg-sky-900/40 px-5 py-4 sm:px-7">
                  <p className="text-xs font-black tracking-[0.16em] text-sky-200">YOUR ESTIMATE</p>
                  <p className="mt-1 text-sm text-slate-300">
                    親1人＋子ども1人・{weeks}週間
                  </p>
                  <p className="mt-1 text-xs font-bold text-sky-200">
                    受講：子ども1人＋親{parentTakesLessons ? '1人' : 'なし'}
                  </p>
                </div>

                <div className="px-5 pb-7 pt-6 sm:px-7 sm:pb-8">
                  <p className="text-sm font-bold text-slate-300">あなたの総額目安</p>
                  <p className="mt-2 flex items-baseline gap-2 whitespace-nowrap">
                    <span className="text-5xl font-black tracking-tight text-white sm:text-6xl">約{estimate.total}</span>
                    <span className="text-xl font-black text-sky-200">万円</span>
                  </p>
                  <p className="mt-3 text-xs leading-5 text-slate-400">授業・宿泊・食事・航空券・保険・学校への現地支払いを含む概算</p>

                  <div className="mt-7 flex h-3 overflow-hidden rounded-full bg-white/10" aria-label="費用構成の比率">
                    {breakdown.map((item) => (
                      <span key={item.label} className={item.tone} style={{ width: `${(item.amount / estimate.total) * 100}%` }} />
                    ))}
                  </div>

                  <div className="mt-5 space-y-3">
                    {breakdown.map((item) => {
                      const Icon = item.icon;
                      return (
                        <div key={item.label} className="grid grid-cols-[auto_1fr_auto] items-center gap-3 rounded-2xl border border-white/10 bg-white/[0.055] p-4">
                          <span className={`grid size-9 place-items-center rounded-xl ${item.tone}`}>
                            <Icon className="size-4.5 text-white" />
                          </span>
                          <div>
                            <p className="text-sm font-black">{item.label}</p>
                            <p className="mt-0.5 text-[11px] text-slate-400">{item.detail}</p>
                          </div>
                          <p className="text-sm font-black text-white">{formatAmount(item.amount)}</p>
                        </div>
                      );
                    })}
                  </div>

                  <Button className="mt-6 h-12 w-full rounded-xl bg-amber-400 text-sm font-black text-slate-950 hover:bg-amber-300">
                    この金額の詳しい内訳を見る
                    <ArrowRight className="size-4" />
                  </Button>
                </div>
              </Card>

              <div className="mt-4 flex items-start gap-3 rounded-2xl border border-slate-200 bg-white/70 p-4 text-xs leading-5 text-slate-600">
                <Users className="mt-0.5 size-4 shrink-0 text-sky-800" />
                <p>学校費用は授業・宿泊・食事、渡航費用は航空券・海外旅行保険、現地費用は受講者1人あたり3.5万円で計算しています。</p>
              </div>
            </aside>
          </div>
        </div>
      </section>
    </main>
  );
}
