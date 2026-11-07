-- CreateTable
CREATE TABLE "Receivable" (
    "id" TEXT NOT NULL,
    "person" TEXT NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "note" TEXT,
    "dueDate" TIMESTAMP(3),
    "status" TEXT NOT NULL DEFAULT 'pending',
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Receivable_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Receivable_userId_idx" ON "Receivable"("userId");

-- AddForeignKey
ALTER TABLE "Receivable" ADD CONSTRAINT "Receivable_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
