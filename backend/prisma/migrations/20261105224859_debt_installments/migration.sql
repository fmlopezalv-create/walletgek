-- AlterTable
ALTER TABLE "Debt" ADD COLUMN     "paidInstallments" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "totalInstallments" INTEGER;
