-- AlterTable
ALTER TABLE "Debt" ADD COLUMN     "details" JSONB,
ADD COLUMN     "institution" TEXT,
ADD COLUMN     "monthsLate" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "paymentType" TEXT,
ADD COLUMN     "status" TEXT NOT NULL DEFAULT 'up_to_date';

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "country" TEXT NOT NULL DEFAULT 'ES';
