export default function PaginationControls({ page, totalPages, hasNext, hasPrevious, onPageChange }) {
  if (!totalPages || totalPages <= 1) {
    return null;
  }

  return (
    <div className="mt-6 flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-white/10 bg-white/5 px-4 py-3">
      <p className="text-xs uppercase tracking-[0.2em] text-slate-500">
        Page {page + 1} of {totalPages}
      </p>
      <div className="flex gap-3">
        <button
          type="button"
          className="secondary-button px-4 py-2 text-xs disabled:cursor-not-allowed disabled:opacity-50"
          disabled={!hasPrevious}
          onClick={() => onPageChange(page - 1)}
        >
          Previous
        </button>
        <button
          type="button"
          className="secondary-button px-4 py-2 text-xs disabled:cursor-not-allowed disabled:opacity-50"
          disabled={!hasNext}
          onClick={() => onPageChange(page + 1)}
        >
          Next
        </button>
      </div>
    </div>
  );
}
