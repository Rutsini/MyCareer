const fs = require('node:fs');
const path = require('node:path');
const { after, before, beforeEach, test } = require('node:test');

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  writeBatch,
} = require('firebase/firestore');

const projectId = 'mycareer-rules-test';
const rules = fs.readFileSync(
  path.resolve(__dirname, '..', '..', 'firestore.rules'),
  'utf8',
);
const timestamp = Timestamp.fromMillis(1760000000000);

let testEnvironment;

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules,
    },
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
});

after(async () => {
  await testEnvironment.cleanup();
});

function authenticatedDb(userId) {
  return testEnvironment
    .authenticatedContext(userId, { email: `${userId}@example.com` })
    .firestore();
}

function unauthenticatedDb() {
  return testEnvironment.unauthenticatedContext().firestore();
}

async function seed(documentPath, data) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), documentPath), data);
  });
}

function profile(overrides = {}) {
  return {
    displayName: 'Ada',
    email: 'alice@example.com',
    career: {
      name: 'Ingeniería',
      currentYear: 4,
      totalSubjects: 42,
      requiredElectivePoints: 20,
    },
    settings: {
      theme: 'system',
      defaultGradeMin: 0,
      defaultGradeMax: 10,
      notifications: {
        enabled: false,
        defaultReminderOffsetsMinutes: [1440],
        allDayReminderHour: 9,
        allDayReminderMinute: 0,
      },
    },
    createdAt: timestamp,
    updatedAt: timestamp,
    schemaVersion: 1,
    ...overrides,
  };
}

function academicYear(overrides = {}) {
  return {
    year: 2026,
    isCurrent: true,
    startDate: null,
    endDate: null,
    createdAt: timestamp,
    updatedAt: timestamp,
    ...overrides,
  };
}

function subject(overrides = {}) {
  return {
    academicYearId: '2026',
    academicYear: 2026,
    trackingMode: 'tracked',
    name: 'Álgebra',
    shortName: null,
    code: null,
    commission: null,
    subjectType: 'mandatory',
    electivePoints: null,
    duration: 'annual',
    semester: null,
    gradeScale: { min: 0, max: 10 },
    recoveryPolicy: 'highestGrade',
    courseStatus: 'active',
    finalOutcome: null,
    finalGrade: null,
    approvedAt: null,
    startDate: null,
    endDate: null,
    notes: null,
    promotionRules: [],
    regularityRules: [],
    createdAt: timestamp,
    updatedAt: timestamp,
    schemaVersion: 2,
    ...overrides,
  };
}

function evaluation(overrides = {}) {
  return {
    subjectId: 'subject-a',
    academicYear: 2026,
    name: 'Parcial 1',
    type: 'partial',
    date: timestamp,
    allDay: true,
    mandatory: true,
    countsTowardAverage: true,
    grade: null,
    maxGrade: 10,
    minimumPassingGradeOverride: null,
    weight: 1,
    presented: null,
    status: 'pending',
    isRecovery: false,
    recoveryOfEvaluationId: null,
    notes: null,
    createdAt: timestamp,
    updatedAt: timestamp,
    reminders: [],
    schemaVersion: 2,
    ...overrides,
  };
}

async function seedAcademicContext(userId = 'alice') {
  await seed(`users/${userId}`, profile({ email: `${userId}@example.com` }));
  await seed(`users/${userId}/academicYears/2026`, academicYear());
  await seed(`users/${userId}/subjects/subject-a`, subject());
}

test('aísla completamente los datos entre usuarios', async () => {
  await seed('users/alice', profile());

  await assertSucceeds(getDoc(doc(authenticatedDb('alice'), 'users/alice')));
  await assertFails(getDoc(doc(authenticatedDb('bob'), 'users/alice')));
  await assertFails(getDoc(doc(unauthenticatedDb(), 'users/alice')));
  await assertFails(
    setDoc(doc(authenticatedDb('bob'), 'users/alice'), profile()),
  );
});

test('valida el esquema completo del perfil', async () => {
  const profilePath = 'users/alice';
  await assertSucceeds(
    setDoc(doc(authenticatedDb('alice'), profilePath), profile()),
  );
  await assertFails(
    setDoc(
      doc(authenticatedDb('alice'), profilePath),
      profile({ admin: true }),
    ),
  );
  await assertFails(
    setDoc(
      doc(authenticatedDb('alice'), profilePath),
      profile({
        settings: {
          theme: 'system',
          defaultGradeMin: 10,
          defaultGradeMax: 0,
          notifications: {
            enabled: false,
            defaultReminderOffsetsMinutes: [-1],
            allDayReminderHour: 30,
            allDayReminderMinute: 0,
          },
        },
      }),
    ),
  );
  await assertFails(deleteDoc(doc(authenticatedDb('alice'), profilePath)));
});

test('rechaza años académicos inválidos o con campos inesperados', async () => {
  const yearPath = 'users/alice/academicYears/2026';
  await assertSucceeds(
    setDoc(doc(authenticatedDb('alice'), yearPath), academicYear()),
  );
  await assertFails(
    setDoc(
      doc(authenticatedDb('alice'), 'users/alice/academicYears/1800'),
      academicYear({ year: 1800 }),
    ),
  );
  await assertFails(
    setDoc(
      doc(authenticatedDb('alice'), yearPath),
      academicYear({ unexpected: true }),
    ),
  );
});

test('una materia requiere un año válido y un esquema estricto', async () => {
  await seed('users/alice', profile());
  await seed('users/alice/academicYears/2026', academicYear());
  const subjectPath = 'users/alice/subjects/subject-a';

  await assertSucceeds(
    setDoc(doc(authenticatedDb('alice'), subjectPath), subject()),
  );
  await assertFails(
    setDoc(
      doc(authenticatedDb('alice'), 'users/alice/subjects/missing-year'),
      subject({ academicYearId: '2025', academicYear: 2025 }),
    ),
  );
  await assertFails(
    setDoc(
      doc(authenticatedDb('alice'), subjectPath),
      subject({ currentCondition: 'promoting' }),
    ),
  );
  await assertFails(
    setDoc(
      doc(authenticatedDb('alice'), subjectPath),
      subject({ subjectType: 'elective', electivePoints: null }),
    ),
  );
  await assertFails(
    setDoc(
      doc(authenticatedDb('alice'), subjectPath),
      subject({
        promotionRules: [
          {
            id: 'invalid-average',
            type: 'minimumAverage',
            name: 'Promedio imposible',
            description: null,
            enabled: true,
            order: 0,
            config: { minimumAverage: 11 },
          },
        ],
      }),
    ),
  );
});

test('una evaluación debe pertenecer a una materia del mismo año', async () => {
  await seedAcademicContext();
  const evaluationPath = 'users/alice/evaluations/evaluation-a';

  await assertSucceeds(
    setDoc(doc(authenticatedDb('alice'), evaluationPath), evaluation()),
  );
  await assertFails(
    setDoc(
      doc(authenticatedDb('alice'), 'users/alice/evaluations/orphan'),
      evaluation({ subjectId: 'missing' }),
    ),
  );
  await assertFails(
    setDoc(
      doc(authenticatedDb('alice'), 'users/alice/evaluations/wrong-year'),
      evaluation({ academicYear: 2025 }),
    ),
  );
  await assertFails(
    setDoc(
      doc(authenticatedDb('alice'), 'users/alice/evaluations/bad-grade'),
      evaluation({ grade: 11 }),
    ),
  );
});

test('los recuperatorios requieren una evaluación original compatible',
    async () => {
      await seedAcademicContext();
      await seed(
        'users/alice/evaluations/original',
        evaluation({ name: 'Parcial original' }),
      );

      await assertSucceeds(
        setDoc(
          doc(authenticatedDb('alice'), 'users/alice/evaluations/recovery'),
          evaluation({
            name: 'Recuperatorio',
            type: 'recovery',
            isRecovery: true,
            recoveryOfEvaluationId: 'original',
          }),
        ),
      );
      await assertFails(
        setDoc(
          doc(
            authenticatedDb('alice'),
            'users/alice/evaluations/missing-original',
          ),
          evaluation({
            name: 'Recuperatorio',
            type: 'recovery',
            isRecovery: true,
            recoveryOfEvaluationId: 'missing',
          }),
        ),
      );
      await assertFails(
        setDoc(
          doc(authenticatedDb('alice'), 'users/alice/evaluations/fake'),
          evaluation({ type: 'recovery' }),
        ),
      );
    });

test('permite la eliminación atómica solo al propietario', async () => {
  await seedAcademicContext();
  await seed('users/alice/evaluations/evaluation-a', evaluation());

  const subjectPath = 'users/alice/subjects/subject-a';
  const evaluationPath = 'users/alice/evaluations/evaluation-a';
  const ownerDb = authenticatedDb('alice');
  const ownerBatch = writeBatch(ownerDb);
  ownerBatch.delete(doc(ownerDb, evaluationPath));
  ownerBatch.delete(doc(ownerDb, subjectPath));
  await assertSucceeds(ownerBatch.commit());

  await seed('users/alice/subjects/subject-a', subject());
  await seed('users/alice/evaluations/evaluation-a', evaluation());
  const attackerDb = authenticatedDb('bob');
  const attackerBatch = writeBatch(attackerDb);
  attackerBatch.delete(doc(attackerDb, evaluationPath));
  attackerBatch.delete(doc(attackerDb, subjectPath));
  await assertFails(attackerBatch.commit());
});
